//
//  JavaScriptCoreServiceHost.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa

final class JavaScriptCoreServiceHost: NSObject, JavaScriptCoreServiceHostProtocol {
    
    func runScriptRunningStateDidUpdate(isRunning: Bool, id: String) {
        JavaScriptCoreService.shared.isXPCScriptRunning.send(isRunning)
        NotificationCenter.default.post(name: JavaScriptCoreServiceHost.runScriptRunningStateDidUpdate, object: isRunning, userInfo: ["id": id])
    }
    
    func screencapDidUpdate(_ screencap: NSImage) {
        ScreencapService.shared.currentSnapshot.send(screencap)
    }
    
    func log(_ string: String, id: String) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: receive log: %s", ((#file as NSString).lastPathComponent), #line, #function, string)
        NotificationCenter.default.post(name: JavaScriptCoreServiceHost.didReceiveLog, object: string, userInfo: ["id": id])
    }
    
    func load(filename: String, id: String, withReply reply: @escaping (String) -> Void) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: require %s", ((#file as NSString).lastPathComponent), #line, #function, filename)
        reply("""
        console.log('module.id: ', module.id);
        console.log('module.exports: ', module.exports);
        console.log('module.parent: ', module.parent);
        console.log('module.filename: ', module.filename);
        console.log('module.loaded: ', module.loaded);
        console.log('module.children: ', module.children);
        console.log('module.paths: ', module.paths);
        """)
    }

    
}

extension JavaScriptCoreServiceHost {
    static var runScriptRunningStateDidUpdate = Notification.Name("JavaScriptCoreServiceHost.runScriptRunningStateDidUpdate")
    static var didReceiveLog = Notification.Name(rawValue: "JavaScriptCoreServiceHost.didReceiveLog")
}
