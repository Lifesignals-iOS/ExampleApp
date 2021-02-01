//
//  DataManager.swift
//
//  Created by Mohammed Janish on 18/12/19.
//  Copyright © 2019 LifeSignals. All rights reserved.
//

import Foundation
let invalidValue: Int32 = -600

class DataManager {
    class func getAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return appVersion
    }
    
    
    class func lsPatchLibVersion() -> String {
        let bundle = Bundle(identifier: "com.hmicro.LSPatch")! // Get a reference to the bundle from your framework (not the bundle of the app itself!)
        let build = bundle.infoDictionary!["CFBundleShortVersionString"] as! String
        return build
    }
 
}

