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
    
    tableView.delegate = self
    tableView.dataSource = self
    
    let itemCellNib = UINib(nibName: String(CheckItemTableViewCell), bundle: nil)
    tableView.registerNib(itemCellNib, forCellReuseIdentifier: "itemCell")
    
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
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadData), name: newItemNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func reloadData() {
    tableView.reloadData()
  }
  
  //MARK: - Actions 
  
  @IBAction func clearButtonAction() {
    OrderManager.currentOrder.clearOrder()
    tableView.reloadData()
  }
  
  @IBAction func checkoutButtonAction() {
    presentAlertWithMessage("checkout")
  }
}

extension CheckViewController: UITableViewDataSource {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = OrderManager.currentOrder.items.count
    
    if count == 0 {
      checkoutButtonView.hidden = true
      tableView.hidden = true
      clearOrderButton.hidden = true
      tableView.backgroundView = {
        $0.backgroundColor = UIColor.whiteColor()
        return $0
      }(UIView())
    } else {
      checkoutButtonView.hidden = false
      tableView.hidden = false
      clearOrderButton.hidden = false
      tableView.backgroundView = nil
    }
    
    return count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let orderItem = OrderManager.currentOrder.items[indexPath.row]
    let cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! CheckItemTableViewCell
    cell.configureWith(orderItem)
    
    return cell
  }
}

extension CheckViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 75
  }
}
