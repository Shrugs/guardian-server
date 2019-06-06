//
//  AppDelegate.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit

extension NSURLRequest {
  static func allowsAnyHTTPSCertificateForHost(host: String) -> Bool {
    return true
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginFlowDelegate {

  var window: UIWindow?


  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.

    window = UIWindow(frame: UIScreen.mainScreen().bounds)
    if let window = window {

      window.rootViewController = ViewController()
      window.makeKeyAndVisible()

      let defaults = NSUserDefaults(suiteName: APP_GROUP_CONTAINER)

      if defaults?.stringForKey("uuid") == nil {
        let login = LoginFlowController()
        login.delegate = self
        window.rootViewController?.presentViewController(login, animated: false, completion: nil)
      }
    }
    return true
  }

  func didFinishLoginFlow(success: Bool) {
    window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

