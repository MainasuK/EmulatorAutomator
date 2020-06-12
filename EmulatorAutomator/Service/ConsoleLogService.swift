//
//  ConsoleLogService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-6-5.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Foundation
import Combine

final class ConsoleLogService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let id: String
    let logs = CurrentValueSubject<[String], Never>([])
    let relay = PassthroughSubject<String, Never>()
    let started = PassthroughSubject<Void, Never>()
    let finished = PassthroughSubject<Void, Never>()
    
    init(id: String) {
        self.id = id
        
        NotificationCenter.default.publisher(for: JavaScriptCoreServiceHost.didReceiveLog)
            .sink { [weak self] notification in
                guard let _id = notification.userInfo?["id"] as? String, id == _id,
                let log = notification.object as? String else {
                    return
                }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: insert log: %s", ((#file as NSString).lastPathComponent), #line, #function, log)
                self?.insert(log: log)
                if !log.hasSuffix("\n") {
                    self?.insert(log: "\n")
                }
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: JavaScriptCoreServiceHost.runScriptRunningStateDidUpdate)
            .sink { [weak self] notification in
                guard let _id = notification.userInfo?["id"] as? String, id == _id,
                let isRunning = notification.object as? Bool else {
                    return
                }
                if isRunning {
                    self?.started.send()
                } else {
                    self?.finished.send()
                }
        }
        .store(in: &disposeBag)
        
    }
    
}

extension ConsoleLogService {
    
    func insert(log: String) {
        logs.value = logs.value + [log]
        relay.send(log)
    }
    
}

