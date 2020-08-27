//
//  AssetOutlineViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-15.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

final class AssetOutlineViewController: OutlineViewController {
    
}

extension AssetOutlineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup outline selection listener
        NotificationCenter.default.addObserver(self, selector: #selector(AssetOutlineViewController.outlineViewSelectionChange(_:)), name: AssetOutlineViewController.NotificationName.selectionChanged, object: nil)
        
        // Setup view model
        viewModel.tree.first?.children = [viewModel.assetsEntry]
        
        viewModel.content
            .sink(receiveValue: { content in
                self.viewModel.willChangeValue(for: \.tree)
                
                let sources = OutlineViewModel.travel(contentNodes: content?.sources ?? [])
                self.viewModel.sourcesEntry.children = sources
                
                let assets = OutlineViewModel.travel(contentNodes: content?.assets ?? [])
                self.viewModel.assetsEntry.children = assets
                
                self.viewModel.didChangeValue(for: \.tree)
            })
            .store(in: &disposeBag)
        
        viewModel.currentSelectionContentNode
            .sink { [weak self] node in
                self?.deleteButton.isEnabled = node != nil
            }
            .store(in: &disposeBag)
    }
    
}

extension AssetOutlineViewController {
    struct NotificationName {
        static let selectionChanged = Notification.Name("AssetOutlineViewController.selectionChanged")
    }
}

extension AssetOutlineViewController {
    
    @objc override func addButtonPressed(_ sender: NSButton) {
//        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let document = document else {
//            assertionFailure()
//            return
//        }
//        var filename = "Untitled"
//        var suffix = 1
//        let fileExtension = ".js"
//        while document.content.sources.contains(where: { $0.name == (filename + fileExtension) }) {
//            filename = "Untitled" + "\(suffix)"
//            suffix += 1
//        }
//
//        let node = Document.Content.Node(name: filename + fileExtension, content: .plaintext(""))
//        document.create(node: node, type: .source)
    }
    
    @objc override func deleteButtonPressed(_ sender: NSButton) {
//        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        guard let document = document else {
//            assertionFailure()
//            return
//        }
//
//        guard let contentNode = viewModel.currentSelectionContentNode.value else {
//            assertionFailure()
//            return
//        }
//
//        let alert = NSAlert()
//        alert.messageText = "Confirm delete file."
//        alert.informativeText = contentNode.name
//        alert.alertStyle = .warning
//        alert.addButton(withTitle: "Delete")
//        alert.addButton(withTitle: "Cancel")
//
//        guard let window = view.window else {
//            if alert.runModal() == .alertFirstButtonReturn {
//                document.delete(node: contentNode, type: .source)
//            }
//
//            return
//        }
//
//        alert.beginSheetModal(for: window) { response in
//            guard response == .alertFirstButtonReturn else {
//                return
//            }
//
//            document.delete(node: contentNode, type: .source)
//        }
    }
    
    @objc override func outlineViewSelectionChange(_ notification: Notification) {
        guard let outlineViewController = notification.object as? AssetOutlineViewController,
        let remoteDocument = outlineViewController.representedObject as? Document,
        let document = representedObject as? Document,
        remoteDocument === document else {
            return
        }
        
        guard let selectionIndexPath = outlineViewController.treeController.selectionIndexPath,
        let selectionTreeNode = outlineViewController.treeController.arrangedObjects.descendant(at: selectionIndexPath) else {
            viewModel.currentSelectionTreeNode.send(nil)
            return
        }
        
        viewModel.currentSelectionTreeNode.send(selectionTreeNode)
    }
    
}

// MARK: - NSOutlineViewDelegate
extension AssetOutlineViewController {
    override func outlineViewSelectionDidChange(_ notification: Notification) {
        NotificationCenter.default.post(name: AssetOutlineViewController.NotificationName.selectionChanged, object: self)
    }
}

