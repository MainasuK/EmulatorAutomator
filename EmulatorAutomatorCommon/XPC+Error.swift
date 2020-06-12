//
//  XPC+Error.swift
//  EmulatorAutomatorCommon
//
//  Created by Cirno MainasuK on 2020-5-11.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation

public struct XPC {

    public enum Error: Swift.Error {
        case `internal`
        case xpc(Swift.Error)
        case scriptStillRunning
    }
    
}

extension XPC.Error: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .internal:
            return "internal error"
        case .xpc(let error):
            return error.localizedDescription
        case .scriptStillRunning:
            return "script still running"
        }
    }
    
}

extension XPC.Error {

    // workaround for XPC lost dynamic errorDescription mapping issue
    public func toNSError() -> NSError {
        let nsError = self as NSError
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: nsError.localizedDescription,
        ]
        return NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
    }
    
}
