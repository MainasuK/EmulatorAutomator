//
//  AppDelegate.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 3/6/20.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine
import AdbAutomator
import CocoaSceneManager

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var disposeBag = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        NSWindow.allowsAutomaticWindowTabbing = false
        
        DispatchQueue.global().async {
            // force restart server and
            Adb.killServer()
            // use dummy command cleanup pipe
            _ = Adb.devices()
        }
        
        // connect XPC
        JavaScriptCoreService.shared.xpc().print().sink(receiveCompletion: { completion in
            
        }, receiveValue: { service in
            service.sayHello(to: "EmulatorAutomator") { message in
                print(message)
            }
        })
        .store(in: &disposeBag)
        
        // AppSceneManager.shared.open(.main)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

extension AppDelegate {
    
    func showWindow(with hostingView: NSView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.contentView = hostingView
        _ = NSWindowController(window: window)
        window.makeKeyAndOrderFront(self)
    }
    
}
