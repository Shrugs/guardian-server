//
//  UIColor+Theme.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit

extension UIColor {

  static func themeColor() -> UIColor {
    return UIColor(hue: 232.0/360.0, saturation: 67.0/100.0, brightness: 67.0/100.0, alpha: 1.0)
  }

  static func highlightColor() -> UIColor {
    return UIColor(hue: 81.0/360.0, saturation: 28.0/100.0, brightness: 100.0/100.0, alpha: 1.0)
  }

  static func darkThemeColor() -> UIColor {
    return UIColor(hue: 233.0/360.0, saturation: 73.0/100.0, brightness: 58.0/100.0, alpha: 1.0)
  }
}

extension UIFont {
  static func themeFont() -> UIFont {
    return UIFont(name: "KannadaSangamMN", size: 50)!
  }

  static func textFont() -> UIFont {
    return UIFont(name: "KannadaSangamMN", size: 30)!
  }


}