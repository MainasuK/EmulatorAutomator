//
//  JavaScriptCoreServiceProtocol.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import EmulatorAutomatorCommon

@objc public protocol JavaScriptCoreServiceProtocol {
    func sayHello(to name: String, withReply: @escaping (String) -> Void)
    func takeScreenshot(withReply: @escaping (NSImage?, NSError?) -> Void)
    
    func run(node: Data, resource: Data, id: String, withReply: @escaping (NSError?) -> Void)
    func stop()
}

