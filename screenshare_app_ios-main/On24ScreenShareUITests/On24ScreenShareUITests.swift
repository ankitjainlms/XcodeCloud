//
//  On24ScreenShareUITests.swift
//  On24ScreenShareUITests
//
//  Created by lms on 19/06/24.
//  Copyright © 2024 TokBox, Inc. All rights reserved.
//

import XCTest
//@testable import On24ScreenShare



final class On24ScreenShareUITests: XCTestCase {
    
    var app: XCUIApplication!
    //var viewController :ViewController!
    // var appDelegate:AppDelegate!
    
    struct AccessibilityIdentifier {
        static let mainScreen = "MainScreen"
        static let rpsbButton = "RPSystemBroadcastPickerView"
        static let lblNoUrl = "LblNoUrl"
        static let viewShare = "ViewScreenShare"
    }
    
    struct TestFailureMessage {
        static let mainScreenNotDisplayed = "MainScreen is not displayed."
        static let rpsystemBroadcastButtonNotFound = "RPSystemBroadcast button is not found."
        static let screenShareNotSuccessful = "Screenshare is not successful."
        static let notComeDeeplinking = "Screen share is not running. Please launch screen share from an ON24 product."
        static let screenShareViewNotDisplayed = "Screen share is not displayed."
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = ["UITEST_RUNNING": "YES"]
        app.launch()
        // viewController = ViewController()
        
    }
    
    
    
    override func tearDownWithError() throws {
        if app != nil {
            app.terminate()
        }
        app = nil
    }
    
    func testSuccessFlow() throws {
    
        // Step 1: Check that the main screen is displayed.
        XCTAssertTrue(app.otherElements[AccessibilityIdentifier.mainScreen].exists, TestFailureMessage.mainScreenNotDisplayed)
        
        let viewShare = app.otherElements[AccessibilityIdentifier.viewShare]
        if viewShare.exists {
            
            // Step 2: Check if the start button exists and then tap it to show the broadcast picker.
            let startButton = app.otherElements[AccessibilityIdentifier.rpsbButton]
            XCTAssertTrue(startButton.exists, TestFailureMessage.rpsystemBroadcastButtonNotFound)
            startButton.tap()
        }
        else
        {
            
            let lbl = app.otherElements[AccessibilityIdentifier.lblNoUrl]
            XCTAssertFalse(lbl.exists, TestFailureMessage.notComeDeeplinking)
            //XCTAssertNotEqual(lbl.title,"Screen share is not running. Please launch screen share from an ON24 product.","msg is not correct")
        }
        
            
    }
    
//    func testLaunchPerformance() throws {
////        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
////            measure(metrics: [XCTApplicationLaunchMetric()]) {
////                XCUIApplication().launch()
////            }
////        }
//    }
}
