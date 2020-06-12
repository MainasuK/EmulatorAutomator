//
//  EAJSContext.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Foundation
import JavaScriptCore

final class EAJSContext: JSContext {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
