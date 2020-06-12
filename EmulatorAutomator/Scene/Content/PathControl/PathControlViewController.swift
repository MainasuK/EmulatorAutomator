//
//  PathControlViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

final class PathControlViewModel {
    
    static var noSelectionPathControlItem: NSPathControlItem {
        let item = NSPathControlItem()
        item.title = "No Selection"
        return item
    }
    
    var disposeBag = Set<AnyCancellable>()

    // Input
    let currentSelectionIndexPathAndTreeNode = CurrentValueSubject<(IndexPath, NSTreeNode)?, Never>(nil)

    // Output
    let latestAvailableSelectionIndexPathAndTreeNode = CurrentValueSubject<(IndexPath, NSTreeNode)?, Never>(nil)
    let currentPathControlItems = CurrentValueSubject<[NSPathControlItem], Never>([PathControlViewModel.noSelectionPathControlItem])
    
    init() {
        currentSelectionIndexPathAndTreeNode
            .filter { tuple in
                guard let (indexPath, treeNode) = tuple else { return false }
                guard let node = treeNode.descendant(at: indexPath)?.representedObject as? OutlineViewModel.Node else { return false }
                switch node.object {
                case .contentNode(let contentNode):
                    return contentNode.isFile
                case .entry(_):
                    return false
                }
            }
            .assign(to: \.value, on: latestAvailableSelectionIndexPathAndTreeNode)
            .store(in: &disposeBag)
        
        latestAvailableSelectionIndexPathAndTreeNode
            .map { tuple -> [NSPathControlItem] in
                guard let (indexPath, treeNode) = tuple else {
                    return [PathControlViewModel.noSelectionPathControlItem]
                }
                var _indexPath = indexPath
                var _nodes: [OutlineViewModel.Node?] = []
                for _ in 0..<indexPath.count {
                    let node = treeNode.descendant(at: _indexPath)?.representedObject as? OutlineViewModel.Node
                    _indexPath = _indexPath.dropLast()
                    _nodes.insert(node, at: 0)
                }
                
                let nodes = _nodes.compactMap { $0 }
                let items = nodes.map { node -> NSPathControlItem in
                    let item = NSPathControlItem()
                    item.title = node.name
                    switch node.object {
                    case .entry(let entry) where entry == .project:
                        break
                    case .entry:
                        item.image = NSImage(named: NSImage.folderName)
                    case .contentNode(let contentNode):
                        if contentNode.isFile {
                            if let url = URL(string: contentNode.name) {
                                item.image = NSWorkspace.shared.icon(forFileType: url.pathExtension)
                            } else {
                                item.image = NSWorkspace.shared.icon(forFileType: "txt")
                            }
                        } else {
                            item.image = NSImage(named: NSImage.folderName)
                        }
                    }
                    return item
                }
                
                return items + [PathControlViewModel.noSelectionPathControlItem]
            }
        .assign(to: \.value, on: currentPathControlItems)
        .store(in: &disposeBag)
    }
    
}

final class PathControlViewController: NSViewController {
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = PathControlViewModel()
    
    lazy var pathControl: NSPathControl = {
        let pathControl = NSPathControl(frame: .zero)
        pathControl.pathStyle = .standard
        pathControl.focusRingType = .none
        pathControl.pathItems = [PathControlViewModel.noSelectionPathControlItem]
        return pathControl
    }()
    
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension PathControlViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pathControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pathControl)
        NSLayoutConstraint.activate([
            pathControl.topAnchor.constraint(equalTo: view.topAnchor),
            pathControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pathControl.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.currentPathControlItems
            .assign(to: \.pathItems, on: pathControl)
            .store(in: &disposeBag)
    }
        
}
