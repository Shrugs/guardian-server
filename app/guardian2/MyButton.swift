//
//  MyButton.swift
//  guardian2
//
//  Created by Matt Condon on 9/13/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit

class MyButton: UIButton {

  convenience init(text: String) {
    self.init()

    self.backgroundColor = .darkThemeColor()
    self.setTitleColor(UIColor.highlightColor(), forState: .Normal)
    self.layer.cornerRadius = 10
    self.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: 20)
    self.setTitle(text, forState: .Normal)
  }

}
