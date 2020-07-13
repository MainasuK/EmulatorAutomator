//
//  SaveAssetWindowController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CocoaSceneManager

final class SaveAssetWindowController: NSWindowController, ManagedController {

    var scene: AppScene?
    
}

extension SaveAssetWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = self.window, let scene = scene else {
            fatalError()
        }
        
        scene.setup(window: window)
    }
    
}
