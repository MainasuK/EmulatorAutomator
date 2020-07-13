//
//  MainWindowController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CocoaSceneManager
import AdbAutomator
import CommonOSLog

fileprivate extension NSToolbarItem.Identifier {

    /// push button for show screencap window
    static let screencap: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "screenCapWindow")
    
    /// push button for run script for Adb device
    static let run: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "run")
    
    /// push button for stop script for Adb device
    static let stop: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "stop")

    /// navigator | debug area | utilities panel control segment
    static let panelControlSegment: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "panelControlSegment")

}

final class MainWindowController: NSWindowController, ManagedController {
    
    var scene: AppScene?
    
    private var disposeBag = Set<AnyCancellable>()
    private var observers = Set<NSKeyValueObservation>()

    private let mainToolbar: NSToolbar = {
        let toolbar = NSToolbar(identifier: String(describing: MainWindowController.self))
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.displayMode = .iconOnly
        return toolbar
    }()

    private enum PanelControl: Int, CaseIterable, CustomStringConvertible {
        case navigator
        case debugArea
        case utility

        var index: Int {
            return self.rawValue
        }

        var image: NSImage {
            return [#imageLiteral(resourceName: "DVTViewNavigators_10_10_Normal"), #imageLiteral(resourceName: "DVTViewDebugArea_10_10_Normal"), #imageLiteral(resourceName: "DVTViewUtilities_10_10_Normal")][self.rawValue]
        }

        func toggle() {
            os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: toggle %{public}s", ((#file as NSString).lastPathComponent), #line, #function, self.description)

            switch self {
            case .navigator:
                MainWindowPreferences.shared.navigatorSidebarExpand.toggle()
            case .debugArea:
                MainWindowPreferences.shared.debugAreaExpand.toggle()
            case .utility:
                MainWindowPreferences.shared.utilitySidebarExpand.toggle()
            }
        }

        var description: String {
            switch self {
            case .navigator: return "navigatorSidebarExpand"
            case .debugArea: return "debugAreaExpand"
            case .utility: return "utilitySidebarExpand"
            }
        }

    }

    private(set) lazy var panelControlSegmentedControl: NSSegmentedControl = {
        let images = PanelControl.allCases.map { $0.image }
        let segmentedControl = NSSegmentedControl(images: images, trackingMode: NSSegmentedControl.SwitchTracking.selectAny, target: self, action: #selector(MainWindowController.panelControlSegmentedControlPressed(_:)))
        return segmentedControl
    }()
    
}

extension MainWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = self.window else {
            fatalError()
        }
        scene!.setup(window: window)

        mainToolbar.delegate = self
        window.toolbar = mainToolbar

        let viewController = MainViewController()
        viewController.scene = scene
        contentViewController = viewController
        
        // bind segment control status with preferences
        MainWindowPreferences.shared
            .observe(\.navigatorSidebarExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = preferences.navigatorSidebarExpand
                self?.panelControlSegmentedControl.setSelected(value, forSegment: PanelControl.navigator.rawValue)
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: navigatorSidebarExpand -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
            }
            .store(in: &observers)

        MainWindowPreferences.shared
            .observe(\.debugAreaExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = preferences.debugAreaExpand
                self?.panelControlSegmentedControl.setSelected(value, forSegment: PanelControl.debugArea.rawValue)
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: debugAreaExpand -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
            }
            .store(in: &observers)

        MainWindowPreferences.shared
            .observe(\.utilitySidebarExpand, options: [.initial, .new]) { [weak self] (preferences, _) in
                let value = preferences.utilitySidebarExpand
                self?.panelControlSegmentedControl.setSelected(value, forSegment: PanelControl.utility.rawValue)
                os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: utilitySidebarExpand -> %s", ((#file as NSString).lastPathComponent), #line, #function, value.description)
            }
            .store(in: &observers)
        
        JavaScriptCoreService.shared.isXPCScriptRunning
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                // do nothing
            }, receiveValue: { [weak self] isRunning in
                guard let `self` = self else { return }
                self.mainToolbar.validateVisibleItems()
            })
            .store(in: &disposeBag)
    }
    
}

extension MainWindowController {
    
    override func newWindowForTab(_ sender: Any?) {
        guard let document = contentViewController?.representedObject as? Document else { return }

        let windowController = AppSceneManager.shared.open(.main(document: document))
        document.addWindowController(windowController)
        windowController.contentViewController?.representedObject = document
        self.window!.addTabbedWindow(windowController.window!, ordered: .above)
    }
    
}

extension MainWindowController: NSToolbarItemValidation {
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case .run:
            return !JavaScriptCoreService.shared.isXPCScriptRunning.value
        case .stop:
            return JavaScriptCoreService.shared.isXPCScriptRunning.value
        default:
            return true
        }
    }

}

extension MainWindowController {
    
    @objc func runToolbarItemPressed(_ sender: NSToolbarItem) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: run triggerd", ((#file as NSString).lastPathComponent), #line, #function)
        
        NotificationCenter.default.post(name: MainWindowController.NotificationName.run, object: contentViewController?.representedObject)
    }
    
    @objc func stopToolbarItemPressed(_ sender: NSToolbarItem) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: stop triggerd", ((#file as NSString).lastPathComponent), #line, #function)
        
        NotificationCenter.default.post(name: MainWindowController.NotificationName.stop, object: contentViewController?.representedObject)
    }

    @objc func screencapToolbarItemPressed(_ sender: NSToolbarItem) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: show screencap window triggerd", ((#file as NSString).lastPathComponent), #line, #function)

        guard let document = contentViewController?.representedObject as? Document else { return }
        
        let windowController = AppSceneManager.shared.open(.screencap(document: document))
        windowController.contentViewController?.representedObject = document
        
//        let windowController = AppSceneManager.shared.open(.main(document: document))
//        document.addWindowController(windowController)
//        windowController.contentViewController?.representedObject = document
//        self.window!.addTabbedWindow(windowController.window!, ordered: .above)
        
        // let newWindowController = MainWindowController(windowNibName: AppScene.appWindowNibName)
        // newWindowController.scene = self.scene
        
        //ScreencapService.shared.screencap(needsSave: true)
    }

    @objc func panelControlSegmentedControlPressed(_ sender: NSSegmentedControl) {
        let selectedSegment = sender.selectedSegment
        guard let control = PanelControl(rawValue: selectedSegment) else {
            assertionFailure()
            return
        }

        control.toggle()
    }

}

//// MARK: - NSToolbarDelegate
extension MainWindowController: NSToolbarDelegate {

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .run:
            let toolbarItem = NSToolbarItem(itemIdentifier: .run)
            toolbarItem.label = "Run"
            toolbarItem.isBordered = true
            toolbarItem.image = #imageLiteral(resourceName: "DVTRun_10_10_Normal")
            toolbarItem.target = self
            toolbarItem.action = #selector(MainWindowController.runToolbarItemPressed(_:))
            return toolbarItem
        case .stop:
            let toolbarItem = NSToolbarItem(itemIdentifier: .stop)
            toolbarItem.label = "Stop"
            toolbarItem.isBordered = true
            toolbarItem.image = #imageLiteral(resourceName: "DVTStop_10_10_Normal")
            toolbarItem.target = self
            toolbarItem.action = #selector(MainWindowController.stopToolbarItemPressed(_:))
            return toolbarItem
        case .screencap:
            let toolbarItem = NSToolbarItem(itemIdentifier: .screencap)
            toolbarItem.label = "Screencap"
            toolbarItem.isBordered = true
            toolbarItem.image = #imageLiteral(resourceName: "camera")
            toolbarItem.target = self
            toolbarItem.action = #selector(MainWindowController.screencapToolbarItemPressed(_:))
            return toolbarItem
        case .panelControlSegment:
            let toolbarItem = NSToolbarItem(itemIdentifier: .panelControlSegment)
            toolbarItem.label = "Panel Control Segement"
            toolbarItem.view = panelControlSegmentedControl

            return toolbarItem

        default:
            return NSToolbarItem()
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .run,
            .screencap,
            .stop,
            .panelControlSegment,
            .space,
            .flexibleSpace,
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .run, .stop, .flexibleSpace, .screencap, .panelControlSegment,
        ]
    }

}

extension MainWindowController {
    
    struct NotificationName {
        static let run = Notification.Name("com.mainasuk.EmulatorAutomator.toolbar.run")
        static let stop = Notification.Name("com.mainasuk.EmulatorAutomator.toolbar.stop")
    }
    
}
