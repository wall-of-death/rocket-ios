//
//  AppDelegate.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/10/16.
//

import AWSCognitoAuth
import AWSCore
import Endpoint
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dependencyProvider: DependencyProvider!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.

        window = UIWindow(frame: UIScreen.main.bounds)
        dependencyProvider = .make(config: DevelopmentConfig.self, windowScene: window!.windowScene!)
        let viewController = HomeViewController(dependencyProvider: dependencyProvider, input: ())
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }

    func application(
        _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return dependencyProvider.auth.application(app, open: url, options: options)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { (byte: UInt8) in String(format: "%02.2hhx", byte) }.joined()
        let req = RegisterDeviceToken.Request(deviceToken: token)
        dependencyProvider.apiClient.request(RegisterDeviceToken.self, request: req) {
            result in
            print(result)
        }
    }

    //    // MARK: UISceneSession Lifecycle
    //
    //    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    //        // Called when a new scene session is being created.
    //        // Use this method to select a configuration to create the new scene with.
    //        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    //    }
    //
    //    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    //        // Called when the user discards a scene session.
    //        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    //        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    //    }

}