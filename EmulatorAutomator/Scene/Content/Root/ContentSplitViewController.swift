//
//  ContentSplitViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-3.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CommonOSLog

final class ContentSplitViewController: NSSplitViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    private var observers = Set<NSKeyValueObservation>()
    
    let editorViewController = EditorViewController()
    let debugAreaViewController = DebugAreaViewController()
    
    private(set) lazy var editorSplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(viewController: editorViewController)
        item.minimumThickness = 100
        item.holdingPriority = .defaultLow - 1
        item.collapseBehavior = .useConstraints
        return item
    }()
    
    private(set) lazy var debugAreaSplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: debugAreaViewController)
        item.minimumThickness = 100
        item.collapseBehavior = .useConstraints
        return item
    }()
    
}

extension ContentSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitView.isVertical = false
        splitViewItems = [editorSplitViewItem, debugAreaSplitViewItem]
        splitView.delegate = self
        
        // bind debug area item to preferences
        debugAreaSplitViewItem.observe(\.isCollapsed, options: [.initial, .new]) { (item, _) in
            let isExpand = !item.isCollapsed
            guard isExpand == MainWindowPreferences.shared.debugAreaExpand else {
                MainWindowPreferences.shared.debugAreaExpand = isExpand
                return
            }
        }
        .store(in: &observers)
        
        // bind preferences to debug area
        MainWindowPreferences.shared
            .observe(\.debugAreaExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = !preferences.debugAreaExpand
                self?.debugAreaSplitViewItem.animator().isCollapsed = value
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: debugAreaSplitViewItem collapsed -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
        }
        .store(in: &observers)
    }
    
}

// MARK: - NSSplitViewDelegate
extension ContentSplitViewController {
    
}
