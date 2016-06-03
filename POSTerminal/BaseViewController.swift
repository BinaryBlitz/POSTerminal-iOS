//
//  BaseViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
  
  @IBOutlet weak var toolBarView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
    
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
  }
}

extension BaseViewController: RedSocketManagerDelegate {
  func cableConnected(protocol: String!) {
    presentAlertWithMessage("Кабель подключен")
  }
  
  func cableDisconnected() {
    presentAlertWithMessage("Кабель отключен")
  }
}