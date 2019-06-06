//
//  LoginFlowController.swift
//  guardian2
//
//  Created by Matt Condon on 9/13/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit

protocol LoginFlowDelegate {
  func didFinishLoginFlow(success: Bool)
}

class LoginFlowController: UIViewController, StartingViewControllerDelegate, UberLoginViewControllerDelegate, ContactSelectionDelegate, EndingViewControllerDelegate {

  var delegate : LoginFlowDelegate?

  var pageViewController : UIPageViewController = {
    var pvc = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    return pvc
  }()

  var viewControllers : [UIViewController] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .themeColor()

    let startingViewController = StartingViewController()
    startingViewController.delegate = self

    let uberLoginController = UberLoginViewController()
    uberLoginController.delegate = self

    let contactPickerController = ContactSelectionViewController()
    contactPickerController.delegate = self

    let endingViewController = EndingViewController()
    endingViewController.delegate = self

    viewControllers = [
      uberLoginController,
      contactPickerController,
      endingViewController
    ]

    pageViewController.setViewControllers([startingViewController], direction: .Forward, animated: true, completion: nil)
    view.addSubview(pageViewController.view)

  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func didBegin() {
    nextPage()
  }

  func didLoginWithUUID(uuid: String) {
    let defaults = NSUserDefaults(suiteName: APP_GROUP_CONTAINER)
    defaults?.setObject(uuid, forKey: "uuid")

    nextPage()
  }

  func didFinishSelectingContacts() {
    nextPage()
  }

  func nextPage() {
    let nextVC = viewControllers.removeFirst()
    pageViewController.setViewControllers([nextVC], direction: .Forward, animated: true, completion: nil)
  }

  func didFinishEndingViewController() {
    delegate?.didFinishLoginFlow(true)
  }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
