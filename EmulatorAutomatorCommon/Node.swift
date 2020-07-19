//
//  Node.swift
//  EmulatorAutomatorCommon
//
//  Created by Cirno MainasuK on 2020-6-7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

@objc public class Node: NSObject, Codable {
    public let id = UUID()
    public dynamic var name: String
    public dynamic var content: Content
    
    public dynamic var children: [Node] = []
    
    public enum CodingKeys: CodingKey {
        case id
        case name
        case content
    }
    
    public init(name: String, content: Content) {
        self.name = name
        self.content = content
        self.children = []
    }
    
}
 
extension Node {
    public enum Content: Codable {
        case directory
        case plaintext(String)
        case image(NSImage)
    
        enum CodingKeys: CodingKey, CaseIterable {
            case directory
            case plaintext
            case image
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            for key in container.allKeys {
                switch key {
                case .directory where container.contains(key):
                    self = .directory
                    return
                case .plaintext where container.contains(key):
                    let value = try container.decode(String.self, forKey: .plaintext)
                    self = .plaintext(value)
                    return
                case .image where container.contains(key):
                    let value = try container.decode(Data.self, forKey: .image)
                    guard let image = NSImage(data: value) else {
                        throw DecodingError.dataCorruptedError(forKey: CodingKeys.image, in: container, debugDescription: "Image Data Corrupted")
                    }
                    self = .image(image)
                    return
                default:
                    continue
                }
            }
            
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: CodingKeys.allCases, debugDescription: "Not Found Value on Key"))
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .directory:
                try container.encode(true, forKey: .directory)
            case .plaintext(let plaintext):
                try container.encode(plaintext, forKey: .plaintext)
            case .image(let image):
                try container.encode(image.tiffRepresentation, forKey: .image)
            }
        }
    }
}

@objc(AutomatorScriptResource) public class AutomatorScriptResource: NSObject, Codable {

    // current selection script
    public let script: String?
    
    // all script nodes
    public let sources: [Node]
    
    // all asset nodes
    public let assets: [Node]
    
    public init(script: String? = nil, sources: [Node], assets: [Node]) {
        self.script = script
        self.sources = sources
        self.assets = assets
    }
    
}
