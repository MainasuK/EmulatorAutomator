//
//  MainWindowPreference.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/12.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import UserDefaultsPreference

final class MainWindowPreferences: NSObject, Preferences {
    
    let defaults: UserDefaults
    
    static var shared: MainWindowPreferences = MainWindowPreferences()
    
    init(defaults: UserDefaults = UserDefaults(suiteName: "MainWindow-shared")!) {
        self.defaults = defaults
    }
    
}

extension MainWindowPreferences {

    @objc dynamic var navigatorSidebarExpand: Bool {
        get { return defaults[#function] ?? true }
        set { defaults[#function] = newValue }
    }

    @objc dynamic var debugAreaExpand: Bool {
        get { return defaults[#function] ?? false }
        set { defaults[#function] = newValue }
    }
    
    @objc dynamic var utilitySidebarExpand: Bool {
        get { return defaults[#function] ?? false }
        set { defaults[#function] = newValue }
    }
    
}
