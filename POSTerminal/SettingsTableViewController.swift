//
//  SettingsTableViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
  
  @IBOutlet weak var wpURLTextField: UITextField!
  @IBOutlet weak var wpUsernameTextField: UITextField!
  @IBOutlet weak var wpPasswordTextField: UITextField!

  @IBOutlet weak var eqURLTextField: UITextField!
  @IBOutlet weak var eqUsernameTextField: UITextField!
  @IBOutlet weak var eqPasswordTextField: UITextField!
  
  @IBOutlet weak var cashBalanceTextField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let settings = Settings.sharedInstance
    
    wpURLTextField.text = settings.wpBase?.baseURL
    wpUsernameTextField.text = settings.wpBase?.login
    wpPasswordTextField.text = settings.wpBase?.password

    eqURLTextField.text = settings.equipServ?.baseURL
    eqUsernameTextField.text = settings.equipServ?.login
    eqPasswordTextField.text = settings.equipServ?.password
    
    cashBalanceTextField.text = String(settings.cashBalance)
  }
  
  //MARK: - Actions
  
  @IBAction func saveButtonAction() {
    view.endEditing(true)
    
    if let url = wpURLTextField.text, username = wpUsernameTextField.text,
        password = wpPasswordTextField.text {
      Settings.sharedInstance.wpBase = Host(baseURL: url, login: username, password: password)
    }
    
    if let url = eqURLTextField.text, username = eqUsernameTextField.text,
        password = eqPasswordTextField.text {
      Settings.sharedInstance.equipServ = Host(baseURL: url, login: username, password: password)
    }
    
    if let balanceString = cashBalanceTextField.text, balance = Double(balanceString) {
      Settings.sharedInstance.cashBalance = balance
    }
    
    Settings.saveToUserDefaults()
    
    presentAlertWithMessage("Настройки сохранены!")
  }
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func checkConnectionButtonAction() {
    presentAlertWithMessage("check")
  }
}
