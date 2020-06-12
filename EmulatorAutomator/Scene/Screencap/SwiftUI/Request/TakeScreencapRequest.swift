//
//  TakeScreencapRequest.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine

struct TakeScreencapRequest {
    
    var publisher: AnyPublisher<NSImage, ScreencapError> {
        ScreencapService.shared.screencap()
            .receive(on: DispatchQueue.main)
            .mapError { ScreencapError.takeScreencapFail($0) }
            .eraseToAnyPublisher()
    }
    
}
