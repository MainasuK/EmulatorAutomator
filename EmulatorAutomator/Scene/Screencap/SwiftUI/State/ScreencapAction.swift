//
//  ScreencapAction.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import AdbAutomator

enum ScreencapAction {
    // General
    case takeScreenshot
    case takeScreenshotDone(result: Result<NSImage, ScreencapError>)
}
