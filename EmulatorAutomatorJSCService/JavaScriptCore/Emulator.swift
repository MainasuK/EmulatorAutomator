//
//  Emulator.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-4-7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine
import JavaScriptCore
import AdbAutomator

@objc protocol EmulatorJSExports: JSExport {
    static func create() -> Self
    func snapshot()
    func tap(_ x: Double, _ y: Double)
    
    func download(handler: JSValue)
    
    func listPackages() -> [String]
    func openPackage(_ string: String)
}


@objc final class Emulator: NSObject, EmulatorJSExports {
    
    var disposeBag = Set<AnyCancellable>()
    
    var screencap = CurrentValueSubject<NSImage?, Never>(nil)
    var error = CurrentValueSubject<Error?, Never>(nil)
    
    let taskQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.JavaScriptCore.Emulator.task-\(UUID().uuidString)")
    
    static func create() -> Emulator {
        return Emulator()
    }
    
    func download(handler: JSValue) {
        var count = 0
        taskQueue.async {
            for _ in 0..<10 {
                handler.call(withArguments: [
                    ["isFinish": false, "isCancelled": count > 5, "date": Date()]
                ])
                count += 1
            }
        }
    }
    
    func listPackages() -> [String] {
        let result = Adb.adb(arguments: ["shell", "pm", "list", "packages"], environment: nil)
        switch result {
        case .success(let string):
            let packages = string.components(separatedBy: .whitespacesAndNewlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return packages
        case .failure(let error):
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            return []
        }
    }
    
    func openPackage(_ package: String) {
        let result = Adb.Shell.Monky.open(package: package)
        switch result {
        case .success(let output):
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, output)
            break
        case .failure(let error):
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
    
}

extension Emulator {
    
    func snapshot() {
        os_log("%{public}s[%{public}ld], %{public}s: snapshot…", ((#file as NSString).lastPathComponent), #line, #function)
        
        let result = Adb.screencapDirect()
        switch result {
        case .success(let image):
            self.screencap.send(image)
        case .failure(let error):
            os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
    
    func tap(_ x: Double, _ y: Double) {
        let point = CGPoint(x: x, y: y)
        _ = Adb.Shell.Input.tap(point: point)
        os_log("%{public}s[%{public}ld], %{public}s: tap %{public}s", ((#file as NSString).lastPathComponent), #line, #function, point.debugDescription)
    }
    
}

extension Emulator {
    
    static func configure(context: JSContext) {
        context.setObject(Emulator.self, forKeyedSubscript: String(describing: Emulator.self) as NSCopying & NSObjectProtocol)
        context.evaluateScript("var emulator = Emulator.create();")
    }
    
}
