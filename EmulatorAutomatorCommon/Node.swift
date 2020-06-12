//
//  Node.swift
//  EmulatorAutomatorCommon
//
//  Created by Cirno MainasuK on 2020-6-7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation

@objc public class Node: NSObject, Codable {
    public let id = UUID()
    public dynamic var name: String
    public dynamic var content: String
    public dynamic var children: [Node]
    public dynamic private(set) var  isFile: Bool
    
    public init(name: String, content: String) {
        self.name = name
        self.content = content
        self.children = []
        self.isFile = true
    }
    
    public init(name: String, children: [Node]) {
        self.name = name
        self.content = ""
        self.children = children
        self.isFile = false
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
