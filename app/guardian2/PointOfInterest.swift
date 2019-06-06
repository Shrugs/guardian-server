//
//  PointOfInterest.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit
import MapKit

class PointOfInterest: NSObject, MKAnnotation {
  @objc let coordinate: CLLocationCoordinate2D
  var title : String?

  init(title: String, coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
    self.title = title
  }
}
