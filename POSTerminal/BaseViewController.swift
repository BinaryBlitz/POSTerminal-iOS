//
//  BaseViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit
import RealmSwift

class BaseViewController: UIViewController {
  
  @IBOutlet weak var toolBarView: UIView!
  var menuNavigationController: UINavigationController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
    
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
    refresh()
  }
  
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
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "menu" {
      menuNavigationController = segue.destinationViewController as? UINavigationController
    }
  }
  
  //MARK: - Actions 
  
  @IBAction func backButtonAction() {
    menuNavigationController?.popViewControllerAnimated(false)
  }
  
  @IBAction func homeButtonAction() {
    menuNavigationController?.popToRootViewControllerAnimated(false)
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