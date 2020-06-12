//
//  ScreencapSplitViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

final class ScreencapSplitViewController: NSSplitViewController {
    
    static let utilityMinimumThickness: CGFloat = 350
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    let screencapContentViewController = ScreencapContentViewController()
    let screencapUtilityViewController = ScreencapUtilityViewController()
    
    private(set) lazy var screencapContentSplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: screencapContentViewController)
        item.collapseBehavior = .useConstraints
        item.canCollapse = false
        item.holdingPriority = .defaultLow - 1
        return item
    }()
    
    private(set) lazy var screencapUtilitySplitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: screencapUtilityViewController)
        item.collapseBehavior = .useConstraints
        item.canCollapse = false
        item.minimumThickness = ScreencapSplitViewController.utilityMinimumThickness
        return item
    }()
    
}

extension ScreencapSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitView.isVertical = true
        splitViewItems = [screencapContentSplitViewItem, screencapUtilitySplitViewItem]
    }
    
}
