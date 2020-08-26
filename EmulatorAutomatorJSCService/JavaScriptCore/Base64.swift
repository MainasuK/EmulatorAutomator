//
//  Base64.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020/8/27.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Foundation
import JavaScriptCore

@objc protocol Base64JSExports: JSExport {
    
    static func btoa(_ string: String) -> String
    static func atob(_ encoded: String) -> String
    
}

@objc final class Base64: NSObject, Base64JSExports {
    
    static func btoa(_ string: String) -> String {
        return Data(string.utf8).base64EncodedString()
    }
    
    static func atob(_ encoded: String) -> String {
        guard let data = Data(base64Encoded: encoded), let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return string
    }
    
}

extension Base64 {
    
    static func configure(context: JSContext) {
        context.setObject(Base64.self, forKeyedSubscript: String(describing: Base64.self) as NSCopying & NSObjectProtocol)
    }
    
}
