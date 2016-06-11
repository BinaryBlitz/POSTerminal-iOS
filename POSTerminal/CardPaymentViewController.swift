//
//  CardPaymentViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 11/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CardPaymentViewController: UIViewController {
  
  @IBOutlet weak var payButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.clearColor()
    
    payButton.layer.cornerRadius = 10
    payButton.backgroundColor = UIColor.elementsAndH1Color()
    payButton.tintColor = UIColor.whiteColor()
  }
  
  //MARK: - Actions
  
  @IBAction func payButtonAction() {
    OrderManager.currentOrder.clearOrder()
    Client.currentClient = nil
    NSNotificationCenter.defaultCenter().postNotificationName(newItemNotification, object: nil)
    navigationController?.popViewControllerAnimated(true)
  }
  
}
