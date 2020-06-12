//
//  ContentViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import JavaScriptCore
import CommonOSLog
import EmulatorAutomatorCommon

final class ContentViewControllerViewModel {
        
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let currentSelectionIndexPathAndTreeNode = CurrentValueSubject<(IndexPath, NSTreeNode)?, Never>(nil)
    let currentSelectionTreeNode = CurrentValueSubject<NSTreeNode?, Never>(nil)

    // output
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    init() {
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

final class ContentViewController: NSViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    weak var document: Document? {
        return representedObject as? Document
    }
    
    var xpcSubscription: AnyCancellable?
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = ContentViewControllerViewModel()
    
    let pathControlViewController = PathControlViewController()
    let splitViewController = ContentSplitViewController()
    
    var currentSelectionContentNode: Document.Content.Node?
    
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ContentViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(pathControlViewController)
        pathControlViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pathControlViewController.view)
        NSLayoutConstraint.activate([
            pathControlViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pathControlViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathControlViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        addChild(splitViewController)
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitViewController.view)
        NSLayoutConstraint.activate([
            splitViewController.view.topAnchor.constraint(equalTo: pathControlViewController.view.bottomAnchor),
            //splitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContentViewController.run(_:)), name: MainWindowController.NotificationName.run, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContentViewController.stop(_:)), name: MainWindowController.NotificationName.stop, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContentViewController.outlineViewSelectionChange(_:)), name: ProjectOutlineViewController.NotificationName.selectionChanged, object: nil)
        
        // bind to path control view model
        viewModel.currentSelectionIndexPathAndTreeNode
            .assign(to: \.value, on: pathControlViewController.viewModel.currentSelectionIndexPathAndTreeNode)
            .store(in: &pathControlViewController.disposeBag)
        
        // bind to editor view model
        viewModel.currentSelectionContentNode
            .assign(to: \.value, on: splitViewController.editorViewController.viewModel.currentSelectionContentNode)
            .store(in: &splitViewController.editorViewController.disposeBag)
    }
    
}

extension ContentViewController {
    
    @objc private func run(_ notification: Notification) {
        guard let remoteDocument = notification.object as? Document, document === remoteDocument else {
            return
        }
        let script: String? = {
            let editorTextView = self.splitViewController.editorViewController.editorTextView
            let string = editorTextView.attributedString().string
            
            // if has text selected. only execute the selection parts
            let selectedRange = editorTextView.selectedRange()
            guard selectedRange.length != 0 else {
                return nil
            }
            let startIndex = string.index(string.startIndex, offsetBy: selectedRange.lowerBound)
            let endIndex = string.index(string.startIndex, offsetBy: selectedRange.upperBound)
            let substring = editorTextView.attributedString().string[startIndex..<endIndex]
            return String(substring)
        }()
        
        guard let document = document else {
            assertionFailure()
            return
        }
        let id = document.content.meta.uuid.uuidString
        
        xpcSubscription = JavaScriptCoreService.shared.xpc()
            .sink(receiveCompletion: { [weak self] completion in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: xpcSubscription disposed", ((#file as NSString).lastPathComponent), #line, #function)
                self?.xpcSubscription = nil
            }, receiveValue: { [weak self] xpc in
                guard let `self` = self else { return }
                guard let currentContentNode = self.viewModel.currentSelectionContentNode.value else { return }
                let nodeData = try! JSONEncoder().encode(currentContentNode)
                let resource = AutomatorScriptResource(script: script, sources: document.content.sources, assets: document.content.assets)
                let resourceData = try! JSONEncoder().encode(resource)
                xpc.run(node: nodeData, resource: resourceData, id: id) { (error) in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: xpc.run error -> %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error?.localizedDescription ?? error.debugDescription)
                }
            })
    }
    
    @objc private func stop(_ notification: Notification) {
        JavaScriptCoreService.shared.stopRunning()
    }
    
    @objc private func outlineViewSelectionChange(_ notification: Notification) {
        guard let outlineViewController = notification.object as? ProjectOutlineViewController,
        let remoteDocument = outlineViewController.representedObject as? Document,
        let document = representedObject as? Document,
        remoteDocument === document else {
            return
        }
        
        guard let selectionIndexPath = outlineViewController.treeController.selectionIndexPath,
        let selectionNode = outlineViewController.treeController.arrangedObjects.descendant(at: selectionIndexPath) else {
            viewModel.currentSelectionTreeNode.send(nil)
            return
        }
        
        let tuple = (selectionIndexPath, outlineViewController.treeController.arrangedObjects)
        viewModel.currentSelectionIndexPathAndTreeNode.send(tuple)
        viewModel.currentSelectionTreeNode.send(selectionNode)
    }
    
}
