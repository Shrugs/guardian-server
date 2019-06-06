//
//  UberLoginViewController.swift
//  guardian2
//
//  Created by Matt Condon on 9/13/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit
import SnapKit

protocol UberLoginViewControllerDelegate {
  func didLoginWithUUID(uuid: String)
}

class UberLoginViewController: UIViewController, UIWebViewDelegate {

  var delegate : UberLoginViewControllerDelegate?

  lazy var webView : UIWebView = {
    var w = UIWebView()
    w.loadRequest(NSURLRequest(URL: NSURL(string: GUARDIAN_BASE_URL + "/login")!))
    return w
  }()

  convenience init() {
    self.init(nibName: nil, bundle: nil)

    webView.delegate = self
    webView.backgroundColor = .themeColor()
    view.addSubview(webView)
    webView.snp_makeConstraints { (make) -> Void in
      make.edges.equalTo(view)
    }
  }


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    if navigationType == .LinkClicked && request.URL?.scheme == "guardian" {

      let uuid = request.URL?.resourceSpecifier.stringByReplacingOccurrencesOfString("//", withString: "")
      if let uuid = uuid {
        delegate?.didLoginWithUUID(uuid)
        return false
      }
    }
    
    return true
  }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
