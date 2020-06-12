//
//  EmulatorAutomatorTests.swift
//  EmulatorAutomatorTests
//
//  Created by MainasuK Cirno on 3/6/20.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import XCTest
import AdbAutomator
@testable import EmulatorAutomator

class EmulatorAutomatorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
}

extension EmulatorAutomatorTests {

    func testSmoke() {

    }
    
    func testListApk() {
        let packages = try! Adb.adb(arguments: ["shell", "pm", "list", "packages", "'-f'"]).get()
        print(packages)
        // package:/data/app/com.hypergryph.arknights-2/base.apk=com.hypergryph.arknights
    }
    
    func testOpenArknights() {
        _ = try! Adb.adb(arguments: ["shell", "monkey", "-p", "com.hypergryph.arknights", "-c", "android.intent.category.LAUNCHER 1"])
    }
    
    func testRect() {
        let imageSize = CGSize(width: 1920, height: 1080)
        let leftOffsetX: CGFloat = 200
        let viewFrame = CGRect(origin: .zero, size: CGSize(width: 1920 + leftOffsetX * 2, height: 1080))
        let imageFrame = CGRect(origin: CGPoint(x: leftOffsetX, y: 0), size: CGSize(width: 1920, height: 1080))

        let offsetInImage: CGFloat = leftOffsetX + 200
        let dragRectInView = CGRect(x: offsetInImage, y: 0, width: 200, height: 200)
        let rectInImage = SelectionArea.convertRectFromViewToImage(rect: dragRectInView, viewFrame: viewFrame, imageFrame: imageFrame, imageSize: imageSize)
        print(rectInImage)
        /// let rectInImage = CGRect(x: 1302, y: 252, width: 181, height: 165)
        /// let rectOnView = CGRect(x: 631, y: 229, width: 87, height: 80)
    }

}
