//
//  UtilityViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa

    
final class UtilityViewController: NSViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            let viewControllers = [fileUtilityViewController, assetUtilityViewController]
            for child in viewControllers {
                child.representedObject = representedObject
            }
        }
    }
    
    let fileUtilityViewController = FileUtilityViewController()
    let assetUtilityViewController = AssetUtilityViewController()
    
    override func loadView() {
        view = NSView()
    }
    
}

extension UtilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        embedChildViewController(fileUtilityViewController)
        
        // Setup navigator segmented selection listener
        NotificationCenter.default.addObserver(self, selector: #selector(UtilityViewController.selectionChanged(_:)), name: NavigatorTabViewController.NotificationName.didSelectViewController, object: nil)
        // Setup outline selection listener
        NotificationCenter.default.addObserver(self, selector: #selector(UtilityViewController.outlineViewSelectionChange(_:)), name: ProjectOutlineViewController.NotificationName.selectionChanged, object: nil)
    }
    
}

extension UtilityViewController {
    
    // handle navigator segmented selection changed
    @objc private func selectionChanged(_ notification: Notification) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let selectViewController = notification.object as? NSViewController
        let viewController = viewControllerForSelectedViewController(selectViewController)
        embedChildViewController(viewController)
    }
    
    // handle outline selection
    @objc private func outlineViewSelectionChange(_ notification: Notification) {
        guard let outlineViewController = notification.object as? ProjectOutlineViewController,
        let remoteDocument = outlineViewController.representedObject as? Document,
        let document = representedObject as? Document,
        remoteDocument === document else {
            return
        }
        
        guard let selectionIndexPath = outlineViewController.treeController.selectionIndexPath,
        let selectionTreeNode = outlineViewController.treeController.arrangedObjects.descendant(at: selectionIndexPath) else {
            fileUtilityViewController.viewModel.currentSelectionTreeNode.send(nil)
            return
        }
        
//        let tuple = (selectionIndexPath, outlineViewController.treeController.arrangedObjects)
//        viewModel.currentSelectionIndexPathAndTreeNode.send(tuple)
        fileUtilityViewController.viewModel.currentSelectionTreeNode.send(selectionTreeNode)
    }
    
}

extension UtilityViewController {
    
    func viewControllerForSelectedViewController(_ viewController: NSViewController?) -> NSViewController? {
        switch viewController {
        case is ProjectOutlineViewController:
            return fileUtilityViewController
        case is AssetTableViewController:
            return assetUtilityViewController
        default:
            assertionFailure()
            return nil
        }
    }
    
    func embedChildViewController(_ viewController: NSViewController?) {
        if !children.isEmpty {
            let childrenViewController = children[0]
            removeChild(at: 0)
            childrenViewController.view.removeFromSuperview()
        }
        
        if let viewController = viewController {
            addChild(viewController)
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(viewController.view)
            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }
    
}
