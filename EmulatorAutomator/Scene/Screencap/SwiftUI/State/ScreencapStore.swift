//
//  ScreencapStore.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import SwiftUI
import Combine
import CommonOSLog
    
final class ScreencapStore: ObservableObject {

    @Published var screencapState = ScreencapState()
    
    let workingQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.ScreencapStore.dispatcher", qos: .userInitiated, target: DispatchQueue.main)
    
    private var disposeBag = Set<AnyCancellable>()
    
    init() {
        
    }
    
    func dispatch(_ action: ScreencapAction) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: [Action] %{publis}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: action))
        
        // make dispatcher queue serial
        workingQueue.async {
            let result = ScreencapStore.reduce(state: self.screencapState, action: action)
            self.screencapState = result.0
            if let command = result.1 {
                os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s: [Command] %{publis}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: command))
                command.execute(in: self)
            }
        }
    }
    
    static func reduce(state: ScreencapState, action: ScreencapAction) -> (ScreencapState, ScreencapCommand?) {
        var screencapState = state
        var screencapCommand: ScreencapCommand? = nil

        switch action {
        case .takeScreenshot:
            screencapCommand = TakeScreencapCommand()
        case .takeScreenshotDone(let result):
            switch result {
            case .success(let image):
                screencapState.content.screencap = image
            case .failure(let error):
                screencapState.content.error = error
            }
        case .makeSelectionOfScreencap(let rect):
            screencapState.content.selectionFrame = rect
        case .resetSelectionOfScreencap:
            screencapState.content.selectionFrame = .zero
        case .setScreenshotCroppedImage(let image):
            screencapState.utility.flannMatchingImage = image
        case .setPreviewResult(let result):
            screencapState.utility.featureMatchingResult = result
        }

        return (screencapState, screencapCommand)
    }
    
}

extension ScreencapStore: Equatable {
    
    static func == (lhs: ScreencapStore, rhs: ScreencapStore) -> Bool {
        return lhs === rhs
    }
    
}
