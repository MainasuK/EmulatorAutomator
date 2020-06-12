//
//  MainSplitViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/8.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CommonOSLog

final class MainSplitViewController: NSSplitViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    private var observers = Set<NSKeyValueObservation>()
        
    let navigatorViewController = NavigatorViewController()
    let contentViewController = ContentViewController()
    let utilityViewController = UtilityViewController()
    
    private(set) lazy var navigatorSplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: navigatorViewController)
        item.minimumThickness = 216
        item.collapseBehavior = .useConstraints
        return item
    }()
    
    private(set) lazy var contentSplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(viewController: contentViewController)
        item.minimumThickness = 100
        item.holdingPriority = .defaultLow - 1
        item.collapseBehavior = .useConstraints
        return item
    }()
    
    private(set) lazy var utilitySplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: utilityViewController)
        item.minimumThickness = 216
        item.collapseBehavior = .useConstraints
        return item
    }()
    
}

extension MainSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true
        splitViewItems = [navigatorSplitViewItem, contentSplitViewItem, utilitySplitViewItem]
                
        // bind navigator item to preferences
        navigatorSplitViewItem.observe(\.isCollapsed, options: [.initial, .new]) { (item, _) in
                let isExpand = !item.isCollapsed
                guard isExpand == MainWindowPreferences.shared.navigatorSidebarExpand else {
                    MainWindowPreferences.shared.navigatorSidebarExpand = isExpand
                    return
                }
            }
            .store(in: &observers)

        // bind preferences to navigator item
        MainWindowPreferences.shared
            .observe(\.navigatorSidebarExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = !preferences.navigatorSidebarExpand
                self?.navigatorSplitViewItem.animator().isCollapsed = value
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: navigatorSplitViewItem collapsed -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
            }
            .store(in: &observers)

        
        // bind utility item to preferences
        utilitySplitViewItem.observe(\.isCollapsed, options: [.initial, .new]) { (item, _) in
                let isExpand = !item.isCollapsed
                guard isExpand == MainWindowPreferences.shared.utilitySidebarExpand else {
                    MainWindowPreferences.shared.utilitySidebarExpand = isExpand
                    return
                }
            }
            .store(in: &observers)

        
        // bind preferences to utility item
        MainWindowPreferences.shared
            .observe(\.utilitySidebarExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = !preferences.utilitySidebarExpand
                self?.utilitySplitViewItem.animator().isCollapsed = value
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: utilitySplitViewItem collapsed -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
            }
            .store(in: &observers)
    }
    
}

