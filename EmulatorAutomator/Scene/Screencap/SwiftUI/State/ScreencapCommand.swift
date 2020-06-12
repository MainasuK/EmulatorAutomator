//
//  ScreencapCommand.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import Combine

protocol ScreencapCommand {
    func execute(in store: ScreencapStore)
}

struct TakeScreencapCommand: ScreencapCommand {
    
    func execute(in store: ScreencapStore) {
        let token = SubscriptionToken()
        
        TakeScreencapRequest()
            .publisher
            .sink(receiveCompletion: { complete in
                if case .failure(let error) = complete {
                    store.dispatch(.takeScreenshotDone(result: .failure(error)))
                }
                token.unseal()
            }, receiveValue: { image in
                store.dispatch(.takeScreenshotDone(result: .success(image)))
            })
            .seal(in: token)
    }
}

class SubscriptionToken {
    var cancellable: AnyCancellable?
    func unseal() { cancellable = nil }
}

extension AnyCancellable {
    func seal(in token: SubscriptionToken) {
        token.cancellable = self
    }
}
