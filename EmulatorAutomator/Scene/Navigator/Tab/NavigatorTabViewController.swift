//
//  NavigatorTabViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-9.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CommonOSLog

final class NavigatorTabViewController: NSTabViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    private let projectOutlineViewController = ProjectOutlineViewController()
    private let assetTableViewController = AssetTableViewController()
    private let operatorTableViewController = AssetTableViewController()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NavigatorTabViewController {
    
    enum NotificationName {
        static let didSelectViewController = Notification.Name("didSelectViewController")
    }
    
}

extension NavigatorTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabStyle = .unspecified
        
        addChild(projectOutlineViewController)
        addChild(assetTableViewController)
        addChild(operatorTableViewController)
    }
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        
        NotificationCenter.default.post(name: NavigatorTabViewController.NotificationName.didSelectViewController, object: tabViewItem?.viewController)
    }
    
}
