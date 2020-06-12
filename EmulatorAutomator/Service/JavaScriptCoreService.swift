//
//  JavaScriptCoreService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import Combine
import CommonOSLog

final class JavaScriptCoreService: NSObject {
    
    static let serviceName = "com.mainasuk.EmulatorAutomator.JavaScriptCoreService"
    
    private let listener = NSXPCListener.anonymous()
    private let connection = NSXPCConnection(serviceName: JavaScriptCoreService.serviceName)
    private let host = JavaScriptCoreServiceHost()
    
    private let workingQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.javaScriptCoreService.Host.working", qos: .userInitiated)
    
    private var disposeBag = Set<AnyCancellable>()
    let isXPCScriptRunning = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Singleton
    public static let shared = JavaScriptCoreService()
    
    private override init() {
        super.init()
        
        listener.delegate = self
        
        connection.remoteObjectInterface = NSXPCInterface(with: JavaScriptCoreServiceProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: JavaScriptCoreServiceHostProtocol.self)
        connection.exportedObject = host
        
        connection.interruptionHandler = {
            self.isXPCScriptRunning.send(false)
        }
        connection.resume()
    }
    
    deinit {
        connection.invalidate()
    }

}

extension JavaScriptCoreService {
    
    var endpoint: NSXPCListenerEndpoint {
        return listener.endpoint
    }
    
    func xpc() -> Future<JavaScriptCoreServiceProtocol, Error> {
        Future { promise in
            DispatchQueue.global().async {
                let _xpc = self.connection.remoteObjectProxyWithErrorHandler { error in
                    self.workingQueue.async {
                        promise(.failure(error))
                    }
                } as? JavaScriptCoreServiceProtocol
                if let xpc = _xpc {
                    self.workingQueue.async {
                        promise(.success(xpc))
                    }
                } else {
                    assertionFailure()
                }
            }
        }
    }
    
}

extension JavaScriptCoreService {
    
    func stopRunning() {
        var subscription: AnyCancellable?
        subscription = xpc().sink(receiveCompletion: { completion in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, subscription.debugDescription)
            subscription = nil
        }, receiveValue: { xpc in
            xpc.stop()
        })
    }
    
}

extension JavaScriptCoreService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = JavaScriptCoreServiceHost()
        newConnection.exportedInterface = NSXPCInterface(with: JavaScriptCoreServiceHostProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
