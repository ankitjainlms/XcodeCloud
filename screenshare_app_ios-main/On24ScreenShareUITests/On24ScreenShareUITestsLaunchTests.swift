//
//  On24ScreenShareUITestsLaunchTests.swift
//  On24ScreenShareUITests
//
//  Created by lms on 28/06/24.
//  Copyright © 2024 TokBox, Inc. All rights reserved.
//

import XCTest

final class On24ScreenShareUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

//    func testLaunch() throws {
//        let app = XCUIApplication()
//        app.launch()
//
//        // Insert steps here to perform after app launch but before taking a screenshot,
//        // such as logging into a test account or navigating somewhere in the app
//
//        let attachment = XCTAttachment(screenshot: app.screenshot())
//        attachment.name = "Launch Screen"
//        attachment.lifetime = .keepAlways
//        add(attachment)
//    }
}
