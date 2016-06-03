//
//  UIViewController+Alert.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

extension UIViewController {
  func presentAlertWithMessage(message: String) {
    presentAlertWithTitle(nil, andMessage: message)
  }
  
  func presentAlertWithTitle(title: String?, andMessage message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    presentViewController(alert, animated: true, completion: nil)
  }
}
