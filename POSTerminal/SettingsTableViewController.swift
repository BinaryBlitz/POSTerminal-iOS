//
//  SettingsTableViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  //MARK: - Actions
  
  @IBAction func saveButtonAction() {
    view.endEditing(true)
    presentAlertWithMessage("Настройки сохранены!")
  }
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
}
