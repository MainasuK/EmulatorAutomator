//
//  Asset.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-30.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation

struct Asset: Codable {
    
    let imageURL: URL
    let name: String
    let dimension: CGSize
    let region: CGRect
    let createAt: Date
    
}

extension Asset {
    
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
