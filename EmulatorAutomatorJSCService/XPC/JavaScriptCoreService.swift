//
//  JavaScriptCoreService.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-10.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog
import AdbAutomator
import EmulatorAutomatorCommon
import JavaScriptCore

final class JavaScriptCoreService: NSObject, JavaScriptCoreServiceProtocol {

    var disposeBag = Set<AnyCancellable>()
    var scriptLoggingSubscription: AnyCancellable?
    var scriptLoggingSubscription2: AnyCancellable?
    var scriptErrorSubscription: AnyCancellable?

    let xpcID = UUID().uuidString
    
    let listener: NSXPCListener
    let connection: NSXPCConnection
    
    var isRunning = false
        
    // XPC working queue
    private let workingQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.javaScriptCoreService.XPC.working", qos: .userInitiated)
    // XPC callback queue
    private let callbackQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.javaScriptCoreService.XPC.callback", qos: .userInteractive, attributes: .concurrent)
    // JSC running queue
    private let runningQueue = DispatchQueue(label: "com.mainasuk.EmulatorAutomator.javaScriptCoreService.XPC.running", qos: .userInitiated)

    init(listener: NSXPCListener, connection: NSXPCConnection) {
        self.listener = listener
        self.connection = connection
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension JavaScriptCoreService {
    
    func sayHello(to name: String, withReply: @escaping (String) -> Void) {
        withReply("Hello, \(name). From: \(xpcID)")
    }
    
    func takeScreenshot(withReply: @escaping (NSImage?, NSError?) -> Void) {
        let result = Adb.screencapDirect()
        
        switch result {
        case .success(let image):
            withReply(image, nil)
            
            var subscription: AnyCancellable? = nil
            // call host
            subscription = service()
                .print()
                .sink(receiveCompletion: { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dispose subscription: %s", ((#file as NSString).lastPathComponent), #line, #function, subscription.debugDescription)
                    subscription = nil
                }, receiveValue: { host in
                    host.screencapDidUpdate(image)
                })
        case .failure(let error):
            withReply(nil, error as NSError)
        }
    }
    
    func run(node: Data, resource: Data, id: String, withReply: @escaping (NSError?) -> Void) {
        guard !isRunning else {
            withReply(XPC.Error.scriptStillRunning.toNSError())
            return
        }
        withReply(nil)
        
        isRunning = true
        var subscription: AnyCancellable?
        subscription = service()
            .sink(receiveCompletion: { completion in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dispose subscription: %s", ((#file as NSString).lastPathComponent), #line, #function, subscription.debugDescription)
                subscription = nil
            }, receiveValue: { host in
                // notify host XPC running
                host.runScriptRunningStateDidUpdate(isRunning: true, id: id)
                
                // setup log notification listener
                self.scriptLoggingSubscription = NotificationCenter.default.publisher(for: JavaScriptCoreHelper.didReceiveLog)
                    .sink { notification in
                        guard let value = notification.object as? JSValue else { return }
    
                        // send log callback to host
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: send log to host: %s", ((#file as NSString).lastPathComponent), #line, #function, value.debugDescription)
                        host.log(value.debugDescription, id: id)
                    }
                self.scriptLoggingSubscription2 = NotificationCenter.default.publisher(for: Emulator.didReceiveLog)
                    .sink { notification in
                        guard let value = notification.object as? String else { return }
                        
                        // send log callback to host
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: send log to host: %s", ((#file as NSString).lastPathComponent), #line, #function, value)
                        host.log(value, id: id)
                    }
                // setup log notification listener
                self.scriptErrorSubscription = NotificationCenter.default.publisher(for: JavaScriptCoreHelper.didReceiveError)
                    .sink { notification in
                        guard let value = notification.object as? JSValue else { return }
                        
                        // send log callback to host
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: send error log to host: %s", ((#file as NSString).lastPathComponent), #line, #function, value.debugDescription)
                        host.log(value.debugDescription, id: id)
                    }
            })
        
        let node = try! JSONDecoder().decode(Node.self, from: node)
        let resource = try! JSONDecoder().decode(AutomatorScriptResource.self, from: resource)
        let context = EAJSContext()!

        runningQueue.async {
            self.isRunning = false

            var subscription_2: AnyCancellable?
            subscription_2 = self.service()
                .sink(receiveCompletion: { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dispose subscription2: %s", ((#file as NSString).lastPathComponent), #line, #function, subscription_2.debugDescription)
                    subscription_2 = nil
                }, receiveValue: { host in
                    let helper = JavaScriptCoreHelper(id: id, host: host, resource: resource)
                    helper.config(context: context) // long live helper until script exit
                    
                    Emulator.resources = resource
                    Emulator.configure(context: context)
                    Base64.configure(context: context)
                    
                    var value: JSValue
                    if let script = resource.script {
                        // selected script
                        value = context.evaluateScript(script)
                    } else {
                        let url = URL(string: node.name)
                        let request = url?.deletingPathExtension().path ?? node.name
                        value = context.evaluateScript("Module.runMain('\(request)');")
                        // value = context.evaluateScript(node.content)
                    }
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: evaluateScript -> %{public}s", ((#file as NSString).lastPathComponent), #line, #function, value.debugDescription)
                    
                    // notify host XPC stopped
                    host.runScriptRunningStateDidUpdate(isRunning: false, id: id)
                })
        }
    }
    
    func stop() {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: raise SIGKILL to stop", ((#file as NSString).lastPathComponent), #line, #function)
        exit(SIGKILL)
    }
    
}

extension JavaScriptCoreService {
    
    func service() -> Future<JavaScriptCoreServiceHostProtocol, XPC.Error> {
        return Future { promise in
            self.workingQueue.async {
                let _service = self.connection.remoteObjectProxyWithErrorHandler { error in
                    self.workingQueue.async {
                        promise(.failure(.xpc(error)))
                    }
                } as? JavaScriptCoreServiceHostProtocol
                if let service = _service {
                    self.workingQueue.async {
                        promise(.success(service))
                    }
                } else {
                    assertionFailure()
                }
            }
        }
    }
    
}

