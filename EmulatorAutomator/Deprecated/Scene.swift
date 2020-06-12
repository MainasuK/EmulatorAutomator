//
//  Scene.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-29.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation

struct Scene: Codable {
    
    let scriptURL: URL
    let name: String
    let createAt: Date
    
}

extension Scene {
    
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
}
