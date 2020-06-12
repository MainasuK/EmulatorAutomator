//
//  main.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import CommonOSLog

os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: XPC startup", ((#file as NSString).lastPathComponent), #line, #function)

let XPCDelegate = JavaScriptCoreServiceXPCListenerDelegate()
let listener = NSXPCListener.service()
listener.delegate = XPCDelegate
listener.resume()
