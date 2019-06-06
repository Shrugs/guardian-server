//
//  ViewController.swift
//  guardian2
//
//  Created by Matt Condon on 9/12/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SnapKit

class ViewController: UIViewController, WatchStreamerDelegate, MKMapViewDelegate {

  let mapView = MKMapView()
  let regionRadius: CLLocationDistance = 400
  let streamer = WatchStreamer()

  var firstUpdate = true

  lazy var banner : UIImageView = {
    let v = UIImageView(image: UIImage(named: "banner")!)
    v.contentMode = .ScaleAspectFit
    v.userInteractionEnabled = true
    return v
  }()

  lazy var infoLabel : UILabel = {
    let l = UILabel()
    l.textAlignment = .Center
    l.font = UIFont(name: "HelveticaNeue-Medium", size: 15)
    l.textColor = .whiteColor()
    l.numberOfLines = 2
    l.lineBreakMode = .ByWordWrapping
    return l
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.themeColor()

    // Do any additional setup after loading the view, typically from a nib.
    streamer.delegate = self

    let tap = UITapGestureRecognizer(target: self, action: "simulateWatchPress")
    tap.numberOfTapsRequired = 3
    tap.numberOfTouchesRequired = 1
    banner.addGestureRecognizer(tap)
    banner.userInteractionEnabled = true
    view.addSubview(banner)
    banner.snp_makeConstraints { (make) -> Void in
      make.left.right.equalTo(view)
      make.top.equalTo(view).offset(10)
      make.height.equalTo(view.snp_height).multipliedBy(0.2)
    }

    mapView.showsUserLocation = false
    mapView.delegate = self
    view.addSubview(mapView)
    mapView.snp_makeConstraints { (make) -> Void in
      make.left.right.equalTo(view)
      make.top.equalTo(banner.snp_bottom)
      make.height.equalTo(view).multipliedBy(0.7)
    }

    view.addSubview(infoLabel)
    infoLabel.userInteractionEnabled = true
    let tap2 = UITapGestureRecognizer(target: self, action: "logout")
    tap2.numberOfTapsRequired = 3
    tap2.numberOfTouchesRequired = 1
    infoLabel.addGestureRecognizer(tap2)
    infoLabel.snp_makeConstraints { (make) -> Void in
      make.bottom.left.right.equalTo(view)
      make.top.equalTo(mapView.snp_bottom)
    }

//    NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "simulateWatchPress", userInfo: nil, repeats: false)
  }

  func logout() {
    NSUserDefaults(suiteName: APP_GROUP_CONTAINER)?.removeObjectForKey("uuid")
  }

  func simulateWatchPress() {
    streamer.didRecieveGTFORequest()
  }

  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKCircle {
      let circle = MKCircleRenderer(overlay: overlay)
      circle.strokeColor = .blueColor()
      circle.fillColor = UIColor(red: 255.0/255.0, green: 0.0, blue: 0.0, alpha: 0.1)
      circle.lineWidth = 1
      return circle
    } else {
      return MKOverlayRenderer(overlay: overlay)
    }
  }

  func didEnterRegion(region: CLCircularRegion) {
    dispatch_async(dispatch_get_main_queue(), {

      self.infoLabel.text = region.identifier

//      let alert = UIAlertController(title: "ENTERED REGION", message: region.identifier, preferredStyle: .Alert)
//      let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
//      alert.addAction(OKAction)
//      self.presentViewController(alert, animated: true, completion: nil)
    });
  }

  func didEndMonitoringForRegion(region: CLCircularRegion) {

  }

  var userLocationOverlay : MKCircle?

  func didUpdateLocation(location: CLLocation) {
    dispatch_async(dispatch_get_main_queue(), {

      if self.firstUpdate {
        self.firstUpdate = false
        self.centerMapOnLocation(location)
      }
      let lat = location.coordinate.latitude
      let lng = location.coordinate.longitude
      let r = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: 20, identifier: "\(lat), \(lng)")
      let circle = MKCircle(centerCoordinate: r.center, radius: r.radius)
      if let overlay = self.userLocationOverlay {
          self.mapView.removeOverlay(overlay)
      }
      self.mapView.addOverlay(circle)
      self.userLocationOverlay = circle
    });

  }

  func didBeginMonitoringNewRegion(region: CLCircularRegion, withTitle title: String) {
    dispatch_async(dispatch_get_main_queue(), {

      let lat = region.center.latitude
      let lng = region.center.longitude
      let radius = region.radius
      let r = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: radius, identifier: "\(lat), \(lng)")
      let circle = MKCircle(centerCoordinate: r.center, radius: r.radius)
      if let overlay = self.userLocationOverlay {
        self.mapView.removeOverlay(overlay)
        let pt = PointOfInterest(title: title, coordinate: r.center)
        self.mapView.addAnnotation(pt)
      }
      self.mapView.addOverlay(circle)
      self.userLocationOverlay = circle
    });
  }

  func didBeginRequestingDirections() {
    dispatch_async(dispatch_get_main_queue(), {
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    });
  }

  func directionsRequestDidEnd(success: Bool) {
    dispatch_async(dispatch_get_main_queue(), {
      MBProgressHUD.hideHUDForView(self.view, animated: true)
    });
  }

  func centerMapOnLocation(location: CLLocation) {
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
      regionRadius * 2.0, regionRadius * 2.0)
    mapView.setRegion(coordinateRegion, animated: true)
  }


  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

