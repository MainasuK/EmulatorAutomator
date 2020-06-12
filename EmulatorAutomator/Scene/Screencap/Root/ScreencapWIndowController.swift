//
//  ScreencapWIndowController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CocoaSceneManager
import CommonOSLog

fileprivate extension NSToolbarItem.Identifier {
    
    /// push button for take screencap for Adb device
    static let screencap: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "screenCap")
    
}

final class ScreencapWindowController: NSWindowController, ManagedController {
    
    var scene: AppScene?
    
    private let screencapToolbar: NSToolbar = {
        let toolbar = NSToolbar(identifier: String(describing: ScreencapWindowController.self))
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.displayMode = .iconOnly
        return toolbar
    }()
    
}

extension ScreencapWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
                
        guard let window = self.window else {
            fatalError()
        }
        
        scene?.setup(window: window)
        
        screencapToolbar.delegate = self
        window.toolbar = screencapToolbar
        
        let viewController = ScreencapViewController()
        viewController.scene = scene
        contentViewController = viewController
    }
    
}

extension ScreencapWindowController {
    
    @objc func screencapToolbarItemPressed(_ sender: NSToolbarItem) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: screencap triggerd", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let screencapViewController = contentViewController as? ScreencapViewController else {
            assertionFailure()
            return
        }
        
        screencapViewController.viewModel.screencapTriggerRelay.send(Void())
    }
    
}

// MARK: - NSToolbarDelegate
extension ScreencapWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .screencap:
            let toolbarItem = NSToolbarItem(itemIdentifier: .screencap)
            toolbarItem.label = "Screencap"
            toolbarItem.isBordered = true
            toolbarItem.image = #imageLiteral(resourceName: "camera")
            toolbarItem.target = self
            toolbarItem.action = #selector(ScreencapWindowController.screencapToolbarItemPressed(_:))
            return toolbarItem

        default:
            return NSToolbarItem()
        }
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .screencap,
            .space,
            .flexibleSpace,
        ]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .screencap, .flexibleSpace,
        ]
    }

}
