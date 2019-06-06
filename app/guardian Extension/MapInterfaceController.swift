//
//  MapInterfaceController.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class MapInterfaceController: WKInterfaceController, WCSessionDelegate {

  let session = WCSession.defaultSession()
  @IBOutlet var myLabel: WKInterfaceLabel!
  @IBOutlet var mapView: WKInterfaceMap!

  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)

    session.delegate = self
    session.activateSession()
    session.sendMessage(["method": "requestGTFO"], replyHandler: nil, errorHandler: nil)
  }

  override func willActivate() {
    super.willActivate()
  }


  func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
    let method = message["method"] as! String
    if method == "displayDirections" {

      let directions = message["directions"] as! String
      let rD = message["relativeDirection"] as! String

      switch rD {
      case RelativeDirection.Forward.rawValue:
        notifyForward()
      case RelativeDirection.Left.rawValue:
        notifyLeft()
      case RelativeDirection.Right.rawValue:
        notifyRight()
      default:
        print("lol idk")
      }
      print(directions)
      myLabel.setText(directions)
      session.sendMessage(["method": "print", "data": "GOT DIRECTION\(rD)"], replyHandler: nil, errorHandler: nil)
    } else if method == "map" {
      let lat = message["lat"] as! Double
      let lng = message["lng"] as! Double
      let coord = CLLocationCoordinate2D(latitude: lat-0.00190026, longitude: lng+0.001312703)
      let latDelta = MKMapPointsPerMeterAtLatitude(lat) * 400
      let size = MKMapSize(width: latDelta, height: latDelta)
      let center = MKMapPointForCoordinate(coord)

      mapView.setVisibleMapRect(MKMapRect(origin: center, size: size))
    } else if method == "annotations" {
      // add annotations to map
      mapView.removeAllAnnotations()
      for coord in message["annotations"] as! [[String: Double]] {
        let lat = coord["lat"]!
        let lng = coord["lng"]!
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        mapView.addAnnotation(center, withPinColor: .Purple)
      }
    }
  }

  func notifyForward() {
    WKInterfaceDevice.currentDevice().playHaptic(.Success)
  }

  func notifyLeft() {
    WKInterfaceDevice.currentDevice().playHaptic(.Retry)
  }

  func notifyRight() {
    WKInterfaceDevice.currentDevice().playHaptic(.Stop)
  }


  override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
  }

}
