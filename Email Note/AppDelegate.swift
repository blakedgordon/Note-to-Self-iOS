//
//  AppDelegate.swift
//  Email Note
//
//  Created by Blake Gordon on 10/28/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Request products to load the price of Pro
        NoteToSelfPro.store.requestProducts { (_, nil) in
            return
        }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NoteToSelfPro.validateReceipt()
        window?.overrideUserInterfaceStyle = (User.darkMode) ? .dark : .light
    }
    
}

