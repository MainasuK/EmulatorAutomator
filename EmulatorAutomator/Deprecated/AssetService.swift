//
//  AssetService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-30.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine

final class AssetService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let assetsMonitor: FolderMonitor?
    let assetsDidChange = PassthroughSubject<Void, Never>()
    let assets = CurrentValueSubject<[Asset], Never>([])
    
    static let shared: AssetService = AssetService()
    private init() {
        do {
            let assetDirectoryURL = try AssetService.applicationAssetsDirectory()
            assetsMonitor = try FolderMonitor(url: assetDirectoryURL)
        } catch {
            assetsMonitor = nil
            assertionFailure()
        }
        
        assetsMonitor?.delegate = self
        
        let updateQueue = DispatchQueue.global(qos: .userInitiated)
        assetsDidChange
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .subscribe(on: updateQueue)
            .map { _ in return AssetService.loadAssets() }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: assets)
            .store(in: &disposeBag)
        
        updateQueue.async {
            let assets = AssetService.loadAssets()
            self.assets.value = assets
        }
    }
    
}

extension AssetService {
    
    func saveScrenncap(image: NSImage) {
        guard let assetsMonitor = assetsMonitor else {
            return
        }
        
        let data = image.tiffRepresentation
            .flatMap { data in NSBitmapImageRep(data: data) }
            .flatMap { bitmap in bitmap.representation(using: .png, properties: [:]) }
        
        guard let pngData = data else { return }
        
        let name = UUID().uuidString
        let folderURL = assetsMonitor.url.appendingPathComponent(name)
        let imageURL = folderURL.appendingPathComponent(name).appendingPathExtension("png")
        let infoURL = folderURL.appendingPathComponent("info").appendingPathExtension("json")
        
        let asset = Asset(
            imageURL: imageURL,
            name: name,
            dimension: image.size,
            region: CGRect(origin: .zero, size: image.size),
            createAt: Date()
        )
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let assetData = try Asset.encoder.encode(asset)
            try assetData.write(to: infoURL, options: .atomic)
            try pngData.write(to: imageURL, options: .atomic)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}

extension AssetService {
    
    private static func loadAssets() -> [Asset] {
        guard let directoryURL = try? applicationAssetsDirectory() else { return [] }
        
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .creationDateKey]
        guard let directoryEnumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) else {
            assertionFailure()
            return []
        }
        
        var assets: [Asset] = []
        for case let url as URL in directoryEnumerator where url.lastPathComponent.lowercased() == "info.json" {
            do {
                let infoData = try Data(contentsOf: url)
                let info = try Asset.decoder.decode(Asset.self, from: infoData)
                assets.append(info)
                
            } catch {
                debugPrint(error)
                os_log("%{public}s[%{public}ld], %{public}s: load asset error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                continue
            }
        }
        
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: load %d assets", ((#file as NSString).lastPathComponent), #line, #function, assets.count)
        return assets.sorted(by: { $0.createAt < $1.createAt })
    }
    
}

// MAKR: - FolderMonitorDelegate
extension AssetService: FolderMonitorDelegate {
    
    func folderMonitorEventHandler(_ monitor: FolderMonitor) {
        assetsDidChange.send(())
    }
    
}

extension AssetService {

    private static func applicationAssetsDirectory() throws -> URL {
        return try FolderMonitor.applicationSupportDocumentDirectory().appendingPathComponent("assets", isDirectory: true)
    }
    
}
