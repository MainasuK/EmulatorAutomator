//
//  OutlineViewModel.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine

final class OutlineViewModel: NSObject {
    
    @objc var tree: [Node] = []
    
    override init() {
        super.init()
        
        tree = []
    }
}

extension OutlineViewModel {
    
    enum OutlineEntry: String {
        case library = "Library"
        case asset = "Asset"
        case scene = "Scene"
        case `operator` = "Operator"
    }
    
    class Node: NSObject {
        let contentNode: Content.Node
        
        var name: String {
            return contentNode.name
        }
        
        @objc var children: [Node] = []
        @objc var count: Int {
            children.count
        }
        @objc var isLeaf: Bool {
            children.isEmpty
        }
        
        init(contentNode: Content.Node, children: [Node] = []) {
            self.contentNode = contentNode
            self.children = children
        }
    }
    
//    static var libraryNode: Node {
//        Node(name: OutlineEntry.library.rawValue, children: [
//            Node(name: OutlineEntry.asset.rawValue),
//            Node(name: OutlineEntry.scene.rawValue),
//            Node(name: OutlineEntry.operator.rawValue),
//        ])
//    }
//
}
