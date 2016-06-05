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
  @IBOutlet weak var backButton: UIButton!
  var menuNavigationController: UINavigationController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
    
    backButton.enabled = false
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
      if let menuController = menuNavigationController?.viewControllers.first as? MenuCollectionViewController {
        menuController.delegate = self
      }
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
  
  private func checkBackButtonState() {
    if let navigationController = menuNavigationController {
      backButton.enabled = navigationController.viewControllers.count > 1
    }
  }
}

extension BaseViewController: MenuCollectionDelegate {
  func menuCollection(collection: MenuCollectionViewController, didSelectProdict product: Product) {
    checkBackButtonState()
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