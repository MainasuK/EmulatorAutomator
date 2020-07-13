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
    
    var disposeBag = Set<AnyCancellable>()
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    // input
    let content = PassthroughSubject<Document.Content, Never>()
    var sourcesEntry = Node(object: .entry(.sources), children: [])
    var assetsEntry = Node(object: .entry(.assets), children: [])
    let currentSelectionTreeNode = CurrentValueSubject<NSTreeNode?, Never>(nil)

    // output
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    @objc private(set) lazy var tree: [Node] = {
        let projectEntry = Node(object: .entry(.project), children: [sourcesEntry, assetsEntry])
        return [projectEntry]
    }()
    
    override init() {
        super.init()
        
        content
            .sink(receiveValue: { [weak self] content in
                guard let `self` = self else { return }
                self.willChangeValue(for: \.tree)
                
                let sources = OutlineViewModel.travel(contentNodes: content.sources)
                self.sourcesEntry.children = sources
                
                let assets = OutlineViewModel.travel(contentNodes: content.assets)
                self.assetsEntry.children = assets
                
                self.didChangeValue(for: \.tree)
            })
            .store(in: &disposeBag)
        
        currentSelectionTreeNode
            .map { treeNode -> Document.Content.Node? in
                guard let node = treeNode?.representedObject as? OutlineViewModel.Node else {
                    return nil
                }
                
                switch node.object {
                case .contentNode(let contentNode):
                    return contentNode
                default:
                    return nil
                }
            }
            .assign(to: \.value, on: currentSelectionContentNode)
            .store(in: &disposeBag)
    }
    
}

extension OutlineViewModel {
    
    static func travel(contentNodes: [Document.Content.Node]) -> [Node] {
        var nodes: [Node] = []
        for contentNode in contentNodes {
            switch contentNode.content {
            case .directory:
                nodes.append(contentsOf: OutlineViewModel.travel(contentNodes: contentNode.children))
            default:
                nodes.append(Node(object: .contentNode(contentNode)))

            }
        }
        return nodes
    }
    
}

extension OutlineViewModel {
    
    class Node: NSObject {
        let object: Object
        
        var name: String {
            switch object {
            case .contentNode(let contentNode):
                return contentNode.name
            case .entry(let entry):
                return entry.rawValue
            }
        }
        
        @objc var children: [Node] = []
        @objc var count: Int {
            children.count
        }
        @objc var isLeaf: Bool {
            switch object {
            case .contentNode(let contentNode):
                switch contentNode.content {
                case .directory:
                    return false
                default:
                    return true
                }

            default:
                return children.isEmpty
            }
        }
        
        init(object: Object, children: [Node] = []) {
            self.object = object
            self.children = children
        }
    }

}

extension OutlineViewModel.Node {
    
    enum Entry: String {
        case project = "Project"
        case sources = "Sources"
        case assets = "Assets"
    }
    
    enum Object {
        case contentNode(Document.Content.Node)
        case entry(Entry)
    }
    
}
