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

//    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        if flag == false {
//            AppSceneManager.shared.open(.main)
//        }
//
//        return true
//    }

}
