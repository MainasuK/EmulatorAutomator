//
//  LibraryTableViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-29.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa

//final class LibraryTableViewController: NSViewController {
//
//    private let sceneTableViewController = SceneTableViewController()
//    private let assetTableViewController = AssetTableViewController()
//
//    override func loadView() {
//        view = NSView()
//    }
//
//}
//
//extension LibraryTableViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // embed default view controller
//        embedChildViewController(assetTableViewController)
//
//        // Setup outline selection listener
//        NotificationCenter.default.addObserver(self, selector: #selector(LibraryTableViewController.selectionChanged(_:)), name: LibraryOutlineViewController.NotificationName.selectionChanged, object: nil)
//    }
//
//}
//
//extension LibraryTableViewController {
//
//    // handle outline selection changed
//    @objc private func selectionChanged(_ notification: Notification) {
//        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        guard let outlineViewController = notification.object as? LibraryOutlineViewController else {
//            return
//        }
//
//        let viewController = viewControllerForSelectedNodes(outlineViewController.treeController.selectedNodes)
//        embedChildViewController(viewController)
//    }
//
//}
//
//extension LibraryTableViewController {
//
//    func viewControllerForSelectedNodes(_ nodes: [NSTreeNode]) -> NSViewController? {
//        switch nodes.count {
//        case 0:
//            return nil
//        case 1:
//            guard let node = nodes[0].representedObject as? OutlineViewModel.Node else {
//                return nil
//            }
//
//            guard let entry =  OutlineViewModel.OutlineEntry(rawValue: node.name) else {
//                assertionFailure()
//                return nil
//            }
//            switch entry {
//            case .library:
//                return nil
//            case .asset:
//                return assetTableViewController
//            case .scene:
//                return sceneTableViewController
//            case .operator:
//                return nil
//            }
//            
//        default:
//            return nil
//        }
//    }
//    
//    func embedChildViewController(_ viewController: NSViewController?) {
//        if !children.isEmpty {
//            let childrenViewController = children[0]
//            removeChild(at: 0)
//            childrenViewController.view.removeFromSuperview()
//        }
//        
//        if let viewController = viewController {
//            addChild(viewController)
//            viewController.view.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(viewController.view)
//            NSLayoutConstraint.activate([
//                viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
//                viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            ])
//        }
//    }
//    
//}
