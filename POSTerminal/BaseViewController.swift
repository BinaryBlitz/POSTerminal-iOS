//
//  BaseViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit
import RealmSwift

let updateMenuNotification = "updateMenuNotification"

class BaseViewController: UIViewController {
  
  @IBOutlet weak var toolBarView: UIView!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var settingsButton: UIButton!
  var menuNavigationController: UINavigationController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
    
    backButton.enabled = false
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
    refresh()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refresh), name: updateMenuNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  //MARK: - Refresh
  
  func refresh() {
    ServerManager.sharedManager.getMenu { (response) in
      switch response.result {
      case .Success(let menu):
        let realm = try! Realm()
        try! realm.write {
          realm.delete(realm.objects(Product))
          realm.add(menu)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(reloadMenuNotification, object: nil)
      case .Failure(let error):
        print("error: \(error)")
      }
    }
  }
  
  //MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "menu" {
      menuNavigationController = segue.destinationViewController as? UINavigationController
      if let menuController = menuNavigationController?.viewControllers.first as? MenuCollectionViewController {
        menuController.delegate = self
      }
    }
  }
  
  private func openSettings() {
    let password = NSBundle.mainBundle().objectForInfoDictionaryKey("SettingsPassword") as! String
    let alert = UIAlertController(title: "Настройки", message: "Введите пароль для доступа к настройкам", preferredStyle: .Alert)
    alert.addTextFieldWithConfigurationHandler { (textField) in
      textField.placeholder = "Пароль"
      textField.secureTextEntry = true
    }
    
    alert.addAction(UIAlertAction(title: "Отмена", style: .Cancel, handler: nil))
    
    alert.addAction(UIAlertAction(title: "Продолжить", style: .Default, handler: { (_) in
      let passwordField = alert.textFields![0]
      if passwordField.text == password {
        self.performSegueWithIdentifier("settings", sender: self)
      } else {
        self.presentAlertWithMessage("Неверный пароль")
      }
    }))
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  //MARK: - Tools
  
  private func checkBackButtonState() {
    if let navigationController = menuNavigationController {
      backButton.enabled = navigationController.viewControllers.count > 1
    }
  }
  
  //MARK: - Actions 
  
  @IBAction func backButtonAction() {
    menuNavigationController?.popViewControllerAnimated(false)
    checkBackButtonState()
  }
  
  @IBAction func homeButtonAction() {
    menuNavigationController?.popToRootViewControllerAnimated(false)
    checkBackButtonState()
  }
  
  @IBAction func settingsButtonAction() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    alert.addAction(UIAlertAction(title: "Управление кассой", style: .Default, handler: { (_) in
      self.performSegueWithIdentifier("eqManagment", sender: self)
    }))
    alert.addAction(UIAlertAction(title: "Настройки", style: .Default, handler: { (_) in
      self.openSettings()
    }))
    
    alert.popoverPresentationController?.sourceView = view
    alert.popoverPresentationController?.sourceRect = settingsButton.frame
    
    presentViewController(alert, animated: true, completion: nil)
  }
}

extension BaseViewController: MenuCollectionDelegate {
  func menuCollection(collection: MenuCollectionViewController, didSelectProdict product: Product) {
    checkBackButtonState()
  }
}

extension BaseViewController: UIPopoverPresentationControllerDelegate {
}

extension BaseViewController: RedSocketManagerDelegate {
  func cableConnected(protocol: String!) {
    presentAlertWithMessage("Кабель подключен")
  }
  
  func cableDisconnected() {
    presentAlertWithMessage("Кабель отключен")
  }
}