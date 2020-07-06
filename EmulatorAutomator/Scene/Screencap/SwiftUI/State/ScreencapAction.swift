//
//  ScreencapAction.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import AdbAutomator
import EmulatorAutomatorCommon

enum ScreencapAction {
    // General
    case takeScreenshot
    case takeScreenshotDone(result: Result<NSImage, ScreencapError>)
    case makeSelectionOfScreencap(rect: CGRect)
    case resetSelectionOfScreencap
    case setScreenshotCroppedImage(image: NSImage)
    case setPreviewResult(result: OpenCVService.FeatureMatchingResult)
}
