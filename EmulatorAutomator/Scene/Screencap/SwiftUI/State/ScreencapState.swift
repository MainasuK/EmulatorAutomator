//
//  AppState.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import EmulatorAutomatorCommon

struct ScreencapState {
    var content = Content()
    var utility = Utility()
}

extension ScreencapState {
    struct Content {
        var screencap = NSImage() {
            didSet { screencapPublisher.send(screencap) }
        }
        let screencapPublisher = PassthroughSubject<NSImage, Never>()
    
        var selectionFrame = CGRect.zero {            // relative to image
            didSet { selectionFramePublisher.send(selectionFrame) }
        }
        let selectionFramePublisher = PassthroughSubject<CGRect, Never>()

        var error: ScreencapError?
    }
}
    
extension ScreencapState {
    struct Utility {
        enum ScriptGenerationType: CaseIterable {
            case tapInTheCenterOfSelection
            
            case listPackages
            case openPackage
        }
        
        var scriptGenerationType: ScriptGenerationType = .tapInTheCenterOfSelection
        var flannMatchingImage = NSImage()
        
        var featureMatchingResult = OpenCVService.FeatureMatchingResult()
    }
}

extension ScreencapState.Utility.ScriptGenerationType {
    var text: String {
        switch self {
        case .tapInTheCenterOfSelection:
            return "Tap in the center of selection"
        case .listPackages:
            return "List packages"
        case .openPackage:
            return "Open package"
        }
    }
}
