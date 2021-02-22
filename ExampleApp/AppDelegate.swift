//
//  AppDelegate.swift
//
//  Created by LifeSignals on 01/10/19.
//  Copyright © 2019 LifeSignals. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        let homeVC = storyBoard.instantiateInitialViewController() as! MainViewController
        self.window?.rootViewController = homeVC
        self.window?.makeKeyAndVisible()

        return true
    }
}

