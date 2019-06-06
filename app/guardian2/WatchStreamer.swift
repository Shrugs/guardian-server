//
//  WatchStreamer.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit
import CoreLocation
import WatchConnectivity

protocol WatchStreamerDelegate {
  func didBeginMonitoringNewRegion(region: CLCircularRegion, withTitle: String)
  func didEndMonitoringForRegion(region: CLCircularRegion)
  func didUpdateLocation(location: CLLocation)
  func didEnterRegion(region: CLCircularRegion)
  func didBeginRequestingDirections()
  func directionsRequestDidEnd(success: Bool)
}

class WatchStreamer: NSObject, WCSessionDelegate, CLLocationManagerDelegate {

  private let locationManager = CLLocationManagerSimulator(file: "gpxmap_converted")
  private let session = WCSession.defaultSession()

  private var didRequestDirections = false
  private var debounceTimer : NSTimer?

  private var hasSentFirstAnnotations = false

  var delegate: WatchStreamerDelegate?

  private lazy var urlSession: NSURLSession = {
    let defaults = NSUserDefaults(suiteName: APP_GROUP_CONTAINER)
    var uuid = defaults?.stringForKey("uuid")
    if uuid == nil {
      print("UUID is nil for some reason")
      exit(1)
    }
    var config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    config.HTTPAdditionalHeaders = [
      "Authorization": "Bearer \(uuid!)"
    ]
    return NSURLSession(configuration: config)
  }()

  private var regionsToMonitor : [CLCircularRegion] = []

  override init() {
    super.init()

    resetLocationManager()

    locationManager.delegate = self
//    locationManager.requestAlwaysAuthorization()
//    locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    locationManager.distanceFilter = 5
    locationManager.startUpdatingLocation()

    session.delegate = self;
    session.activateSession()
  }

  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    guard let location = locations.first else {
      print("No location?")
      // try and get another
      return
    }

    delegate?.didUpdateLocation(location)

    session.sendMessage([
      "method": "map",
      "lat": location.coordinate.latitude,
      "lng": location.coordinate.longitude
    ], replyHandler: nil, errorHandler: nil)

    // collision detection

    for region in regionsToMonitor {
      if region.containsCoordinate(location.coordinate) {
        self.locationManager(locationManager, didEnterRegion: region)
      }
    }

    if !hasSentFirstAnnotations {
      sendAnnotations()
      hasSentFirstAnnotations = true
    }

    if didRequestDirections {
      debounceTimer?.invalidate()
      debounceTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "requestDirections:", userInfo: location, repeats: false)

      didRequestDirections = false
    }

  }

  func requestDirections(timer: NSTimer) {
    delegate?.didBeginRequestingDirections()


    for region in regionsToMonitor {
//      locationManager.stopMonitoringForRegion(region)
      delegate?.didEndMonitoringForRegion(region)
    }
    regionsToMonitor = []

    let location = timer.userInfo as! CLLocation
    let lat = location.coordinate.latitude
    let lng = location.coordinate.longitude

    // @TODO(shrugs) - fix for prod
    let speed = location.speed
    let direction = location.course

    let baseURL = "\(GUARDIAN_BASE_URL)/the-fuck-out-of-here"
    let fullURL = "\(baseURL)?speed=\(speed)&direction=\(direction)&lat=\(lat)&lng=\(lng)"
    let getMeOutOfHereUrl = NSURL(string: fullURL)

    urlSession.dataTaskWithURL(getMeOutOfHereUrl!) { (data, response, error) -> Void in

      guard (response as! NSHTTPURLResponse).statusCode == 200 else {
        print("No acceptable routes")
        self.delegate?.directionsRequestDidEnd(false)
        return
      }
      self.delegate?.directionsRequestDidEnd(true)

      var legs : [[String: AnyObject]] = []
      var json : [String: AnyObject]!
      do {
        json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? [String: AnyObject]
        legs = json["legs"] as! [[String: AnyObject]]
      } catch _ {
        print("could not deserialize")
        return
      }

      for leg in legs {
        if let steps = leg["steps"] as? [[String: AnyObject]] {
          self.didGetSteps(steps)
        }
      }

      if let lastLeg = legs.last {
        let startLocation = lastLeg["end_location"] as! [String: Double]
        let description = "Head forward and find your UberX"
        let coord = CLLocationCoordinate2DMake(startLocation["lat"]!, startLocation["lng"]!)
        let region = CLCircularRegion(center: coord, radius: 10, identifier: description)
        region.notifyOnEntry = true
        region.notifyOnExit = false
//        self.locationManager.startMonitoringForRegion(region)
        self.delegate?.didBeginMonitoringNewRegion(region, withTitle: description)
        self.regionsToMonitor.append(region)
      }

      // TESTING
//      for ll in json["snapped"] as! [[String: Double]] {
//        let lat = ll["lat"]!
//        let lng = ll["lng"]!
//        let r = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: 10, identifier: "\(lat), \(lng)")
//        self.delegate?.didBeginMonitoringNewRegion(r, withTitle: "\(lat), \(lng)")
//      }
//      for ll in json["preSnapped"] as! [[String: Double]] {
//        let lat = ll["lat"]!
//        let lng = ll["lng"]!
//        let r = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: 10, identifier: "\(lat), \(lng)")
//        self.delegate?.didBeginMonitoringNewRegion(r, withTitle: "\(lat), \(lng)")
//      }

    }.resume()
  }

  func didGetSteps(steps: [[String: AnyObject]]) {
    for step in steps {
      // get start_location
      let startLocation = step["start_location"] as! [String: Double]
      var description = step["html_instructions"] as! String
      description = description.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)

      let coord = CLLocationCoordinate2DMake(startLocation["lat"]!, startLocation["lng"]!)
      let region = CLCircularRegion(center: coord, radius: 25.0, identifier: description)

      region.notifyOnEntry = true
      region.notifyOnExit = false

//      self.locationManager.startMonitoringForRegion(region)
      self.delegate?.didBeginMonitoringNewRegion(region, withTitle: description)
      regionsToMonitor.append(region)
    }


    let r = regionsToMonitor[0]
    self.locationManager(locationManager, didEnterRegion: r)
  }


  // MARK: WCSessionDelegate and Handlers

  func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
    dispatch_async(dispatch_get_main_queue(), {


      let method = message["method"] as! String
      switch method {
      case "requestGTFO":
        self.didRecieveGTFORequest()
      case "print":
        print(message["data"] as! String)
      default:
        print("UNKNOWN: \(message)")
      }
    });
  }

  func didRecieveGTFORequest() {
    let authorizationStatus = CLLocationManager.authorizationStatus()
    guard authorizationStatus == .AuthorizedAlways else {
      print("NOT AUTHORIZED")
      return
    }

    didRequestDirections = true
  }

  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("ENTERED: \(region.identifier)")

    // assume the region entered is always the first
    guard regionsToMonitor.count >= 1 else {
      print(regionsToMonitor)
      return
    }

    let r = regionsToMonitor.removeFirst()
    delegate?.didEnterRegion(r as CLCircularRegion)

    let directions = region.identifier

    var relativeDirection = RelativeDirection.Forward
    if directions.rangeOfString("Head") != nil {
      relativeDirection = .Forward
    } else if directions.rangeOfString("left") != nil {
      relativeDirection = .Left
    } else if directions.rangeOfString("right") != nil {
      relativeDirection = .Right
    }

    session.sendMessage([
      "method": "displayDirections",
      "directions": directions,
      "relativeDirection": relativeDirection.rawValue
      ], replyHandler: nil, errorHandler: nil)

    sendAnnotations()
  }

  func sendAnnotations() {
    let annotations : [[String: Double]] = regionsToMonitor.map { (region: CLCircularRegion) -> [String: Double] in
      return [
        "lat": region.center.latitude,
        "lng": region.center.longitude
      ]
    }
    let message : [String: AnyObject] = [
      "method": "annotations",
      "annotations": annotations
    ]
    session.sendMessage(message, replyHandler: nil, errorHandler: nil)
  }

  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print(error)
  }

  func resetLocationManager() {
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoringForRegion(region)
    }
  }
}

















