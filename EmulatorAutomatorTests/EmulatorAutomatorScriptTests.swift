//
//  EmulatorAutomatorScriptTests.swift
//  EmulatorAutomatorTests
//
//  Created by Cirno MainasuK on 2020-4-7.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import XCTest
import JavaScriptCore
@testable import EmulatorAutomator

class EmulatorAutomatorScriptTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
}

extension EmulatorAutomatorScriptTests {

    func testSmoke() throws { }
    
    func testEmulatorSnapshot() {
        let context = JSContext()!
        context.setObject(Emulator.self, forKeyedSubscript: String(describing: Emulator.self) as NSCopying & NSObjectProtocol)
        let script = """
        var emulator = Emulator.shared()
        emulator.snapshot()
        """
        context.evaluateScript(script)
    }

}
