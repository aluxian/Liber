//
//  AppDelegate.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase
import AimBrainSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var functions = Functions.functions()
    
    lazy var phoneNumber: String? = UserDefaults.standard.string(forKey: "logged_in_phone_number")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        AMBNManager.sharedInstance().configure(withApiKey: "a3ede39e-8fea-4d06-b3ed-55d7687964f3", secret: "ywWFIRscVUPFcC8ZBi3SKzgb3nCB7Q86a43Crum4dvwsZ/7BEb/WIbhUnl8mlx9C1eD/ic0Z9yzBSEbzP2XvGQ==")
    
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

