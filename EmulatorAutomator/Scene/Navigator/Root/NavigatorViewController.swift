//
//  NavigatorViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI
import CocoaPreviewProvider

final class NavigatorViewController: NSViewController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    private lazy var tabSegmentedControl: NSSegmentedControl = {
        let segmentedControl = NSSegmentedControl()
        segmentedControl.cell?.isBordered = false
        segmentedControl.segmentCount = 3
        segmentedControl.segmentDistribution = .fit
        segmentedControl.setImage(#imageLiteral(resourceName: "rectangle.grid"), forSegment: 0)
        segmentedControl.setImage(#imageLiteral(resourceName: "photo"), forSegment: 1)
        segmentedControl.setImage(#imageLiteral(resourceName: "book"), forSegment: 2)
        
        return segmentedControl
    }()
    private let separatorLine: NSBox = {
        let box = NSBox()
        box.boxType = .separator
        return box
    }()
    private let navigatorTabViewController = NavigatorTabViewController()
        
    override func loadView() {
        view = NSView()
    }
    
}


extension NavigatorViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabSegmentedControl)
        NSLayoutConstraint.activate([
            tabSegmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            tabSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            //tabSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 2),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        addChild(navigatorTabViewController)
        navigatorTabViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigatorTabViewController.view)
        NSLayoutConstraint.activate([
            navigatorTabViewController.view.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            navigatorTabViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigatorTabViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigatorTabViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // tabSegmentedControl.bind(NSBindingName.content, to: navigatorTabViewController, withKeyPath: "tabViewItems", options: nil)
        tabSegmentedControl.bind(NSBindingName.selectedIndex, to: navigatorTabViewController, withKeyPath: "selectedTabViewItemIndex", options: nil)
    }
    
}

struct NavigatorViewController_Previews: PreviewProvider {
    static var previews: some View {
        NSViewControllerPreview {
            NavigatorViewController()
        }
    }
}
