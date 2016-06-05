//
//  EquipmentManagementTableViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 06/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class EquipmentManagementTableViewController: UITableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
}
