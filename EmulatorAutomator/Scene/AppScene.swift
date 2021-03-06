//
//  AppScene.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CocoaSceneManager
import CommonOSLog

enum AppScene: ManagableScene {
    
    static let appWindowNibName = "AppWindow"
    
    static var lastTabID = 0
    case main(document: Document, tabID: Int)
    case screencap(document: Document)
    case saveAsset(document: Document, screencapStore: ScreencapStore)
    
    var windowMinSize: NSSize {
        switch self {
        case .screencap:
            // magic 1241 make screencap fit & fill 
            return NSSize(width: 1241 + ScreencapSplitViewController.utilityMinimumThickness, height: 720)
        case .saveAsset:
            return NSSize(width: 400, height: 150)
        default:
            return NSSize(width: 800, height: 450)
        }
    }
 
}

extension AppScene {
    
    static func main(document: Document) -> AppScene {
        let tabID = lastTabID
        lastTabID += 1
        
        let scene = AppScene.main(document: document, tabID: tabID)
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: open main scene %{public}s", ((#file as NSString).lastPathComponent), #line, #function, scene.identifier)
        
        return scene
    }
    
}

extension AppScene {
    
    var identifier: Self.ID {
        switch self {
        case .main(let document, let tabID):
            return "com.mainasuk.EmulatorAutomator.window.main-\(document.content.meta.uuid.uuidString)-\(tabID)"
        case .screencap(let document):
            return "com.mainasuk.EmulatorAutomator.window.screencap-\(document.content.meta.uuid.uuidString)"
        case .saveAsset(let document, _):
            return "com.mainasuk.EmulatorAutomator.window.saveAsset-\(document.content.meta.uuid.uuidString)"
        }
    }
    
    var windowController: NSWindowController {
        switch self {
        case .main:
            let windowController = MainWindowController(windowNibName: AppScene.appWindowNibName)
            windowController.scene = self
            
            return windowController
        case .screencap:
            let windowController = ScreencapWindowController(windowNibName: AppScene.appWindowNibName)
            windowController.scene = self
            
            return windowController
        case .saveAsset(let document, let store):
            let modalWindowFrame = CGRect(origin: .zero, size: windowMinSize)
            
            let contentViewController = SaveAssetViewController()
            contentViewController.representedObject = document
            contentViewController.screencapStore = store
            contentViewController.view.frame = modalWindowFrame
            
            let window = NSWindow(contentViewController: contentViewController)
            window.minSize = modalWindowFrame.size
            
            let windowController = SaveAssetWindowController(window: window)
            windowController.scene = self
            
            return windowController
        }
    }
    
}
