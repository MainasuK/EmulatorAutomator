//
//  SceneService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-30.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Foundation
import Combine

final class SceneService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let scenesMonitor: FolderMonitor?
    let scenesDidChange = PassthroughSubject<Void, Never>()
    let scenes = CurrentValueSubject<[Scene], Never>([])

    
    static let shared: SceneService = SceneService()
    private init() {
        do {
            let scenesDirectoryURL = try SceneService.applicationScenesDirectory()
            scenesMonitor = try FolderMonitor(url: scenesDirectoryURL)
        } catch {
            scenesMonitor = nil
            assertionFailure()
        }
        
        scenesMonitor?.delegate = self
        
        let updateQueue = DispatchQueue.global(qos: .userInitiated)
        scenesDidChange
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .subscribe(on: updateQueue)
            .map { _ in return SceneService.loadScenes() }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: scenes)
            .store(in: &disposeBag)
        
        updateQueue.async {
            let scenes = SceneService.loadScenes()
            self.scenes.value = scenes
        }
    }
    
}

extension SceneService {
    
    func createScene() {
        guard let scenesMonitor = scenesMonitor else { return }
        
        let name = UUID().uuidString
        let folderURL = scenesMonitor.url.appendingPathComponent(name)
        let scriptURL = folderURL.appendingPathComponent("script").appendingPathExtension("js")
        let sceneURL = folderURL.appendingPathComponent("info").appendingPathExtension("json")
        
        let scene = Scene(scriptURL: scriptURL, name: name, createAt: Date())
        let emptyScript = """
        // scene script
        var emulator = Emulator.shared
        """
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let sceneData = try Scene.encoder.encode(scene)
            try sceneData.write(to: sceneURL, options: .atomic)
            try emptyScript.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}

extension SceneService {
    
    private static func loadScenes() -> [Scene] {
        guard let directoryURL = try? applicationScenesDirectory() else { return [] }
        
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .creationDateKey]
        guard let directoryEnumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) else {
            assertionFailure()
            return []
        }
        
        var scenes: [Scene] = []
        for case let url as URL in directoryEnumerator where url.lastPathComponent.lowercased() == "info.json" {
            do {
                let infoData = try Data(contentsOf: url)
                let info = try Scene.decoder.decode(Scene.self, from: infoData)
                scenes.append(info)
                
            } catch {
                debugPrint(error)
                os_log("%{public}s[%{public}ld], %{public}s: load scene error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                continue
            }
        }
        
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: load %d assets", ((#file as NSString).lastPathComponent), #line, #function, scenes.count)
        return scenes.sorted(by: { $0.createAt < $1.createAt })
    }
    
}

// MAKR: - FolderMonitorDelegate
extension SceneService: FolderMonitorDelegate {
    
    func folderMonitorEventHandler(_ monitor: FolderMonitor) {
        scenesDidChange.send(())
    }
    
}


extension SceneService {
    
    private static func applicationScenesDirectory() throws -> URL {
        return try FolderMonitor.applicationSupportDocumentDirectory().appendingPathComponent("scenes", isDirectory: true)
    }
    
}
