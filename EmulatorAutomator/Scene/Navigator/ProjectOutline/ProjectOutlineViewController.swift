//
//  ProjectOutlineViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

final class ProjectOutlineViewController: NSViewController {
    
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
        case name = "com.mainasuk.EmulatorAutomator.ProjectOutlineViewController.nameColumn"
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
        let button = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(ProjectOutlineViewController.addButtonPressed(_:)))
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        return button
    }()
    
    struct NotificationName {
        static let selectionChanged = Notification.Name("selectionChanged")
    }
    
    override func loadView() {
        view = NSView()
    }
    
}

extension ProjectOutlineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomToolbarStackView = NSStackView()
        bottomToolbarStackView.alignment = .centerY
        bottomToolbarStackView.spacing = 0
        
        bottomToolbarStackView.addArrangedSubview(addButton)
        //bottomToolbarStackView.addArrangedSubview(removeButton)
        
        bottomToolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbarStackView)
        NSLayoutConstraint.activate([
            bottomToolbarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbarStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 22),
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor, multiplier: 1.0),
            //removeButton.widthAnchor.constraint(equalToConstant: 22),
            //removeButton.heightAnchor.constraint(equalTo: removeButton.widthAnchor, multiplier: 1.0),
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
    }
    
}

extension ProjectOutlineViewController {
    
    @objc private func addButtonPressed(_ sender: NSButton) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let document = document else {
            assertionFailure()
            return
        }
        var filename = "Untitled"
        var suffix = 1
        let fileExtension = ".js"
        while document.content.sources.contains(where: { $0.name == (filename + fileExtension) }) {
            filename = "Untitled" + "\(suffix)"
            suffix += 1
        }
    
        let node = Document.Content.Node(name: filename + fileExtension, content: "")
        document.createSourceNode(node: node)
    }
    
}

// MARK: - NSOutlineViewDelegate
extension ProjectOutlineViewController: NSOutlineViewDelegate {
    
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
        NotificationCenter.default.post(name: ProjectOutlineViewController.NotificationName.selectionChanged, object: self)
    }
    
}

