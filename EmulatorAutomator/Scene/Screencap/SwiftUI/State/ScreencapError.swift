//
//  ScreencapError.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import AdbAutomator

enum ScreencapError: Error {
    case takeScreencapFail(Adb.Error)
}
