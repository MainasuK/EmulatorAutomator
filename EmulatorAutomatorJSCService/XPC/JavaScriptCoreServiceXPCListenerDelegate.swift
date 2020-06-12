//
//  JavaScriptCoreServiceXPCListenerDelegate.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import CommonOSLog

final class JavaScriptCoreServiceXPCListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: new connection", ((#file as NSString).lastPathComponent), #line, #function)
        let exportedObject = JavaScriptCoreService(listener: listener, connection: newConnection)
        newConnection.exportedInterface = NSXPCInterface(with: JavaScriptCoreServiceProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.remoteObjectInterface = NSXPCInterface(with: JavaScriptCoreServiceHostProtocol.self)
        newConnection.resume()
        return true
    }
}
