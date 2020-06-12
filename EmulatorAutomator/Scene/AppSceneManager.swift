//
//  AppSceneManager.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CocoaSceneManager

final class AppSceneManager: SceneManager<AppScene> {
    
    // MARK: - Singleton
    public static let shared = AppSceneManager()

    private override init() {
        super.init()
    }
    
}
