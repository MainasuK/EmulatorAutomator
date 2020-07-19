//
//  OutlineViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-15.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

class OutlineViewController: NSViewController {
    
    var contentDisposeBag = Set<AnyCancellable>()
    var disposeBag = Set<AnyCancellable>()
    
    override var representedObject: Any? {
        didSet {
            weak var document = representedObject as? Document
            
            contentDisposeBag.removeAll()
            if let document = document {
                viewModel.content.send(document.content)
                document.content.objectWillChange
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.viewModel.content.send(document.content)
                }
                .store(in: &contentDisposeBag)
            }
        }
    }
    
    weak var document: Document? {
        return representedObject as? Document
    }
    
    let viewModel = OutlineViewModel()
    
    private(set) lazy var treeController: NSTreeController = {
        let treeController = NSTreeController()
        treeController.objectClass = OutlineViewModel.Node.self
        treeController.childrenKeyPath = #keyPath(OutlineViewModel.Node.children)
        treeController.countKeyPath = #keyPath(OutlineViewModel.Node.count)
        treeController.leafKeyPath = #keyPath(OutlineViewModel.Node.isLeaf)
        return treeController
    }()
    
    enum OutlineColumn: String {
        case name = "com.mainasuk.EmulatorAutomator.OutlineViewController.nameColumn"
    }
    
    private(set) lazy var outlineView: NSOutlineView = {
        let outlineView = NSOutlineView()
        
        let taskColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(OutlineColumn.name.rawValue))
        outlineView.addTableColumn(taskColumn)
        
        outlineView.selectionHighlightStyle = .sourceList
        
        outlineView.headerView = nil
        
        return outlineView
    }()
    
    private(set) lazy var addButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(OutlineViewController.addButtonPressed(_:)))
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        return button
    }()
    
    private(set) lazy var deleteButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.removeTemplateName)!, target: self, action: #selector(OutlineViewController.deleteButtonPressed(_:)))
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        return button
    }()
    
    override func loadView() {
        view = NSView()
    }
    
}

extension OutlineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomToolbarStackView = NSStackView()
        bottomToolbarStackView.alignment = .centerY
        bottomToolbarStackView.spacing = 0
        
        bottomToolbarStackView.addArrangedSubview(addButton)
        bottomToolbarStackView.addArrangedSubview(deleteButton)
        
        bottomToolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbarStackView)
        NSLayoutConstraint.activate([
            bottomToolbarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbarStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 22),
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor, multiplier: 1.0),
            deleteButton.widthAnchor.constraint(equalToConstant: 22),
            deleteButton.heightAnchor.constraint(equalTo: deleteButton.widthAnchor, multiplier: 1.0),
        ])
        
        // Layout outlineView
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView, positioned: .below, relativeTo: bottomToolbarStackView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        scrollView.documentView = outlineView
        
        // Setup treeController
        treeController.bind(
            NSBindingName("contentArray"),
            to: viewModel,
            withKeyPath: #keyPath(OutlineViewModel.tree),
            options: nil
        )
        
        // Setup OutlineView
        outlineView.bind(NSBindingName(rawValue: "content"),
                         to: treeController,
                         withKeyPath: #keyPath(NSTreeController.arrangedObjects),
                         options: nil)
        outlineView.bind(NSBindingName(rawValue: "selectionIndexPaths"),
                         to: treeController,
                         withKeyPath: #keyPath(NSTreeController.selectionIndexPaths),
                         options: nil)
        outlineView.delegate = self
        
        if self.treeController.arrangedObjects.children?.isEmpty == false {
            self.outlineView.expandItem(self.treeController.arrangedObjects.children![0], expandChildren: true)
        }
        
        // Setup view model
        viewModel.currentSelectionContentNode
            .sink { [weak self] node in
                self?.deleteButton.isEnabled = node != nil
        }
        .store(in: &disposeBag)
    }
    
}

extension OutlineViewController {
    
    @objc func addButtonPressed(_ sender: NSButton) {
        // not implement
    }
    
    @objc func deleteButtonPressed(_ sender: NSButton) {
        // not implement
    }
    
    @objc func outlineViewSelectionChange(_ notification: Notification) {
        // not implement
    }
    
}

// MARK: - NSOutlineViewDelegate
extension OutlineViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let identifier = tableColumn?.identifier,
            let column = OutlineColumn(rawValue: identifier.rawValue) else {
                return nil
        }
        
        guard let treeNode = item as? NSTreeNode,
            let node = treeNode.representedObject as? OutlineViewModel.Node else {
                return nil
        }
        
        var view: NSTableCellView
        switch column {
        case .name:
            let cell = LibraryOutlineTableCellView()
            cell.name.send(node.name)
            
            view = cell
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        // not implement
    }
    
}

