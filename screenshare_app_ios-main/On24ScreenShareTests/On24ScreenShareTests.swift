//
//  On24ScreenShareTests.swift
//  On24ScreenShareTests
//
//  Created by ADMIN on 18/06/24.
//  Copyright © 2024 TokBox, Inc. All rights reserved.
//

import XCTest



final class On24ScreenShareTests: XCTestCase {
    var appDelegate: AppDelegate!
    var viewController:ViewController!
    
    
    override func setUp() {
        super.setUp()
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewController = ViewController()
       
       
    }
    
    override func tearDown() {
        appDelegate = nil
        viewController = nil
        super.tearDown()
    }
    
    func testForUrlSchema() {
        let url = URL(string: testURL)
        let options: [UIApplication.OpenURLOptionsKey: Any] = [:]
        let result = appDelegate.application(UIApplication.shared, open: url!, options: options)
        XCTAssertTrue(result)
        XCTAssertEqual(url?.scheme, "on24screenshare")
    }
   
    
    func testForDictionaryPreprationWithQueryParam(){
        let url = URL(string: testURL)!
        guard let dic = appDelegate.prepareDictionary(withQueryPram: url) else {
            XCTFail("dicVonageInfo is nil")
            return
        }
        appDelegate.dicVonageInfo = dic
        
        XCTAssertNotNil(dic, "Dic is nil")
        XCTAssertTrue(viewController.isValidDic(dic), "Dic is invalid")
        
        
    }
    
    
    
    func testForEmptyDictionary() {
        let url = URL(string: testURL)!
        
        
        
        guard let dic = appDelegate.prepareDictionary(withQueryPram: url) else {
            XCTFail("dicVonageInfo is nil")
            return
        }
        if !viewController.isValidApiKey(dic["apiVonage"] as? String) {
            XCTFail("api value is missing or empty")
        }
        if !viewController.isValidSessionId(dic["sessionIdVonage"] as? String) {
            XCTFail("sessionId value is missing or empty")
        }
        if !viewController.isValidToken(dic["tokenVonage"] as? String) {
            XCTFail("token value is missing or empty")
            
        }
    }
    
    func testForTokenLength() {
        let url = URL(string: testURL)!
        
        guard let dic = appDelegate.prepareDictionary(withQueryPram: url) else {
            XCTFail("dicVonageInfo is nil")
            return
        }
        
        let token = dic.value(forKey:"tokenVonage") as? String
        
        // Check if the token is not nil or empty
        XCTAssertNotNil(token, "Token should not be nil")
        XCTAssertFalse((token!.isEmpty),"Token is empty")
        
        let length = viewController.getTokenLength(token)
        
        // Print the length for debugging
        print("Token Length: \(length)")
        
        // Assert the length is within an expected range (this range is arbitrary for illustration)
        XCTAssertGreaterThan(length, 100, "Token length should be greater than 100")
        XCTAssertLessThan(length, 2000, "Token length should be less than 2000")
    }
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
   
    
//    func testPerformanceExample() throws {
////        // This is an example of a performance test case.
////        self.measure {
////            // Put the code you want to measure the time of here.
////        }
//    }
    
}
