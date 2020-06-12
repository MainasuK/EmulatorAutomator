//
//  JavaScriptCoreServiceHostProtocol.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

@objc protocol JavaScriptCoreServiceHostProtocol {
    
    func runScriptRunningStateDidUpdate(isRunning: Bool, id: String)
    // notify host screencap update
    func screencapDidUpdate(_ screencap: NSImage)
    func log(_ string: String, id: String)
    func load(filename: String, id: String, withReply reply: @escaping (String) -> Void)
}
