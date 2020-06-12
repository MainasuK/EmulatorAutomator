//
//  ScreencapService.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/13.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import AdbAutomator
import CommonOSLog

final class ScreencapService {
    
    static let shared: ScreencapService = ScreencapService()

    private let screencapQueue = DispatchQueue(label: "com.mainasuk.ArkAutomator.screencapQueue", qos: .userInitiated)

    // snapshot update from XPC
    let currentSnapshot = PassthroughSubject<NSImage, Never>()
    
    private init() { }
    
}

extension ScreencapService {
    
    func screencap() -> Future<NSImage, Adb.Error> {
        Future { promise in
            self.screencapQueue.async {
                let result = Adb.screencapDirect()
                
                switch result {
                case .success(let image):
                    promise(.success(image))
                case .failure(let error):
                    os_log(.debug, log: .logic, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    promise(.failure(error))
                }
            }
        }   // end Future
    }
    
}
