//
//  JavaScriptCoreHelper.swift
//  EmulatorAutomatorJSCService
//
//  Created by Cirno MainasuK on 2020-5-3.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import Combine
import JavaScriptCore
import CommonOSLog
import EmulatorAutomatorCommon

class JavaScriptCoreHelper {
    
    let id: String
    let host: JavaScriptCoreServiceHostProtocol
    let resource: AutomatorScriptResource
    
    weak var context: JSContext?
        
    init(id: String, host: JavaScriptCoreServiceHostProtocol, resource: AutomatorScriptResource) {
        self.id = id
        self.host = host
        self.resource = resource
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: init %s", ((#file as NSString).lastPathComponent), #line, #function, id)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deinit %s", ((#file as NSString).lastPathComponent), #line, #function, id)
    }
    
    lazy var resolve: @convention(block) (_ filename: String) -> (Bool) = { [unowned self] filename in
        let lastPathComponent = URL(string: filename)?.lastPathComponent ?? filename
        let resovled = self.resource.sources.contains(where: { $0.name == lastPathComponent })
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: revolve %s: %s", ((#file as NSString).lastPathComponent), #line, #function, filename, resovled.description)
        return resovled
    }
    
    lazy var dirname: @convention(block) (_ filename: String) -> String = { [unowned self] filename in
        let url = URL(string: filename)
        let dirname = url?.deletingLastPathComponent().path ?? "."
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: dirname for %s: %s", ((#file as NSString).lastPathComponent), #line, #function, filename, dirname)
        return dirname
    }
    
    lazy var readFileSync: @convention(block) (_ filename: String) -> String = { [unowned self] filename in
        let lastPathComponent = URL(string: filename)?.lastPathComponent ?? filename
        guard let node = self.resource.sources.first(where: { $0.name == lastPathComponent }) else {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: not found %s", ((#file as NSString).lastPathComponent), #line, #function, lastPathComponent)
            return ""
        }
        let content = node.content
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s : length %d", ((#file as NSString).lastPathComponent), #line, #function, lastPathComponent, content.count)
        return content
    }
    
    lazy var runInThisContext: @convention(block) (_ content: String, _ options: JSValue) -> JSValue? = { [unowned self] content, options in
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: runInThisContext with options %s", ((#file as NSString).lastPathComponent), #line, #function, (options.toDictionary() ?? [:]).debugDescription)
        return self.context?.evaluateScript(content)
    }
    
    let debug: @convention(block) (JSValue) -> (Void) = { message in
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: -> %s", ((#file as NSString).lastPathComponent), #line, #function, message.debugDescription)
    }
    
    let consoleLog: @convention(block) (JSValue) -> (Void) = { message in
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: console.log: %s", ((#file as NSString).lastPathComponent), #line, #function, message.debugDescription)
        NotificationCenter.default.post(name: JavaScriptCoreHelper.didReceiveLog, object: message)
    }
    
    let sleep: @convention(block) (UInt32) -> (Void) = { sec in
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sleep %d sec", ((#file as NSString).lastPathComponent), #line, #function, sec)
        Thread.sleep(forTimeInterval: TimeInterval(sec))

//        let group = DispatchGroup()
//        group.enter()
//        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(sec)) {
//            group.leave()
//        }
//        group.wait()
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: weakup", ((#file as NSString).lastPathComponent), #line, #function, sec)
    }

}

extension JavaScriptCoreHelper {
    
    func config(context: JSContext) {
        self.context = context
        
        context.exceptionHandler = { context, exception in
            NotificationCenter.default.post(name: JavaScriptCoreHelper.didReceiveError, object: exception)
            os_log("%{public}s[%{public}ld], %{public}s: JS Error: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: exception))
        }
                
        // util.debuglog
        context.setObject(self.debug, forKeyedSubscript: "_debug" as NSCopying & NSObjectProtocol)
        context.evaluateScript("var util = { debuglog: function(message) { _debug(message) } }")
        
        // console.log(…)
        context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        context.setObject(self.consoleLog, forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
        
        // sleep(sec)
        context.setObject(self.sleep, forKeyedSubscript: "sleep" as NSCopying & NSObjectProtocol)
        
        // assert(…, message)
        context.evaluateScript("""
        function assert(expected, message) {
            if (!expected) {
                throw new Error(message);
            }
        }
        """
        )
        
        // NativeModule
        // _resolve
        context.setObject(self.resolve, forKeyedSubscript: "_resolve" as NSCopying & NSObjectProtocol)
        context.setObject(self.dirname, forKeyedSubscript: "_dirname" as NSCopying & NSObjectProtocol)
        context.setObject(self.readFileSync, forKeyedSubscript: "_readFileSync" as NSCopying & NSObjectProtocol)
        context.evaluateScript(#"""
        var NativeModule = {
            exists: function(filename) {
                return false;
            },
            resolve: function(module) {
                return _resolve(module);
            },
            dirname: function(filename) {
                return _dirname(filename);
            },
            readFileSync: function(filename) {
                return _readFileSync(filename);
            },
            wrapper: [
                '(function (exports, require, module, __filename, __dirname) { \n',
                '\n});'
            ],
            wrap: function(script) {
                return this.wrapper[0] + script + this.wrapper[1];
            },
        }
        """#
        )
        
        context.setObject(runInThisContext.self, forKeyedSubscript: "_runInThisContext" as NSCopying & NSObjectProtocol)
        //context.setObject(runInNewContext.self, forKeyedSubscript: "_runInNewContext" as NSCopying & NSObjectProtocol)
        context.evaluateScript("""
        var vm = {
            runInThisContext: function(context, options) {
                return _runInThisContext(context, options);
            },
        }
        """
        )
        
        let bundle = Bundle(for: JavaScriptCoreService.self)
        // let moduleURL = URL(fileURLWithPath: "/Users/mainasuk/Developer/EmulatorAutomator/EmulatorAutomatorJSCService/Vender/NodeJS/module.js")
        let moduleURL = bundle.url(forResource: "module", withExtension: "js")!
        let moduleJS = try! String(contentsOf: moduleURL)
        
        context.evaluateScript(moduleJS)
    }
    
}

extension JavaScriptCoreHelper {
    static var didReceiveLog = Notification.Name("JavaScriptCoreHelper.didReceiveLog")
    static var didReceiveError = Notification.Name("JavaScriptCoreHelper.didReceiveError")
}
