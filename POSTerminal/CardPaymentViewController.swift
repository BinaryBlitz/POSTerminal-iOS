//
//  CardPaymentViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 11/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CardPaymentViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  //MARK: - Actions
  
  func payButtonAction() {
    OrderManager.currentOrder.clearOrder()
    Client.currentClient = nil
    NSNotificationCenter.defaultCenter().postNotificationName(newItemNotification, object: nil)
    navigationController?.popViewControllerAnimated(true)
  }
  
}
