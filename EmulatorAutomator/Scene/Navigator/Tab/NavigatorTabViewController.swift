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
    
    private let sourceOutlineViewController = SourceOutlineViewController()
    private let assetOutlineViewController = AssetOutlineViewController()
    private let operatorTableViewController = AssetOutlineViewController()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NavigatorTabViewController {
    
    enum NotificationName {
        static let didSelectViewController = Notification.Name("NavigatorTabViewController.didSelectViewController")
    }
    
}

extension NavigatorTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabStyle = .unspecified
        
        addChild(sourceOutlineViewController)
        addChild(assetOutlineViewController)
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
