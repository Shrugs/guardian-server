//
//  ContactSelectionViewController.swift
//  guardian2
//
//  Created by Matt Condon on 9/13/15.
//  Copyright © 2015 mattc. All rights reserved.
//

import UIKit
import Contacts
import AddressBook

public extension CNContact {

  public var fullName : String? {
    get {
      return CNContactFormatter.stringFromContact(self, style: .FullName)
    }
  }

  public var phoneNumberStrings : [String] {
    get {
      var numbers = [String]()
      for number in self.phoneNumbers {
        let numberString = number.value as! CNPhoneNumber
        numbers.append(numberString.stringValue)
      }
      return numbers
    }
  }

}

protocol ContactSelectionDelegate {
  func didFinishSelectingContacts()
}

class ContactSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  var delegate : ContactSelectionDelegate?
  var people : [CNContact] = []
  let tableView = UITableView()

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

  override func viewDidLoad() {
    super.viewDidLoad()

    let info = UILabel()
    info.numberOfLines = 2
    info.textAlignment = .Center
    info.text = "Select an Emergency Contact"
    info.textColor = .whiteColor()
    info.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
    view.addSubview(info)
    info.snp_makeConstraints { (make) -> Void in
      make.left.right.equalTo(view)
      make.top.equalTo(view).offset(30)
      make.height.equalTo(view).multipliedBy(0.1)
    }

    tableView.separatorColor = .clearColor()
    tableView.backgroundColor = .clearColor()
    tableView.delegate = self
    tableView.dataSource = self

    view.addSubview(tableView)
    tableView.snp_makeConstraints { (make) -> Void in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(info.snp_bottom)
    }

    getContacts()

  }

  func getContacts() {

    CNContactStore().requestAccessForEntityType(.Contacts) { (success, error) -> Void in
      guard success else { return }

      let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName)])
      request.predicate = nil

      do {
        try CNContactStore().enumerateContactsWithFetchRequest(request, usingBlock: { (contact, whatever) -> Void in
          self.people.append(contact)
        })
      } catch _ {
        print("whelp")
      }

      self.tableView.reloadData()

    }

  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var c = tableView.dequeueReusableCellWithIdentifier("cell")
    if c == nil {
      c = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
    }

    c?.backgroundColor = .clearColor()

    c!.textLabel?.textColor = .whiteColor()
    c!.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 30)
    c!.textLabel?.text = CNContactFormatter.stringFromContact(people[indexPath.row], style: .FullName)

    c!.detailTextLabel?.textColor = .whiteColor()
    c!.detailTextLabel?.text = people[indexPath.row].phoneNumberStrings.first

    let v = UIView()
    v.frame = c!.frame
    v.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
    c!.selectedBackgroundView = v

    return c!
  }


  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    MBProgressHUD.showHUDAddedTo(view, animated: true)
    let phoneNumber = people[indexPath.row].phoneNumberStrings.first!
      .stringByReplacingOccurrencesOfString(" ", withString: "")
      .stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!


    let addContactURL = NSURL(string: "\(GUARDIAN_BASE_URL)/add-contact-number?contact=\(phoneNumber)")
    urlSession.dataTaskWithURL(addContactURL!) { (data, response, error) -> Void in

      guard (response as! NSHTTPURLResponse).statusCode == 200 else {
        dispatch_async(dispatch_get_main_queue()) {
          MBProgressHUD.hideHUDForView(self.view, animated: true)
        }
        return
      }

      dispatch_async(dispatch_get_main_queue()) {
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        self.delegate?.didFinishSelectingContacts()
      }
      
    }.resume()
  }

  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 80
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return people.count
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }


  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }


}
