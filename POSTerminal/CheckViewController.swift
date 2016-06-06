//
//  CheckViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CheckViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var clearOrderButton: UIButton!
  @IBOutlet weak var clientInfoCard: CardView!
  @IBOutlet weak var checkoutButtonView: CardView!
  
  @IBOutlet weak var clientNameLabel: UILabel!
  @IBOutlet weak var clientBalanceLabel: UILabel!
  @IBOutlet weak var clientPhotoImageView: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.whiteColor()
    tableView.backgroundColor =  UIColor.whiteColor()
    
//    tableView.delegate = self
    tableView.dataSource = self
    
    clientPhotoImageView.image = UIImage(named: "avatarExample")
    clientPhotoImageView.clipsToBounds = true
    clientPhotoImageView.contentMode = .ScaleAspectFill
    clientPhotoImageView.layer.cornerRadius = 17.5
    
    clientNameLabel.textColor = UIColor.h4Color()
    clientBalanceLabel.textColor = UIColor.h5Color()
    
    if let client = Client.currentClient {
      clientNameLabel.text = client.name
      clientBalanceLabel.text = "Баланс: \(client.balance) р."
    } else {
      clientNameLabel.text = "Новый клиент"
      clientBalanceLabel.hidden = true
    }
    
    clearOrderButton.tintColor = UIColor.h3Color()
    
    clientInfoCard.backgroundColor = UIColor.whiteColor()
    checkoutButtonView.backgroundColor = UIColor.elementsAndH1Color()
  }
  //MARK: - Actions 
  
  @IBAction func clearButtonAction() {
    presentAlertWithMessage("clear")
  }
  
  @IBAction func checkoutButtonAction() {
    presentAlertWithMessage("checkout")
  }
}

extension CheckViewController: UITableViewDataSource {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return {
        $0.textLabel?.text = "кек"
        return $0
      }(UITableViewCell())
  }
}
