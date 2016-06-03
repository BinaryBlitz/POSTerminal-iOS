//
//  BaseViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
  }
  
  func presentAlertWithMessage(message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    presentViewController(alert, animated: true, completion: nil)
  }
}

extension BaseViewController: RedSocketManagerDelegate {
  func cableConnected(protocol: String!) {
    presentAlertWithMessage("Cabel connected")
  }
  
  func cableDisconnected() {
    presentAlertWithMessage("Cabel disconnected")
  }
}