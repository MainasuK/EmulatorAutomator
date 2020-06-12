//
//  MainViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine
import CocoaSceneManager
import AdbAutomator
import CommonOSLog

final class MainViewController: NSViewController, ManagedController {
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
        
    var scene: AppScene?
    private let mainSplitViewController = MainSplitViewController()
    
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension MainViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(mainSplitViewController)
        mainSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainSplitViewController.view)
        NSLayoutConstraint.activate([
            mainSplitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainSplitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainSplitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainSplitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
}
