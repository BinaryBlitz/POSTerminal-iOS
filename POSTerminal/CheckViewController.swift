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
  
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  
  @IBOutlet weak var totalPriceLabel: UILabel!
  
  var items = [OrderItem]()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.whiteColor()
    tableView.backgroundColor =  UIColor.whiteColor()
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableFooterView = UIView()
    
    let itemCellNib = UINib(nibName: String(CheckItemTableViewCell), bundle: nil)
    tableView.registerNib(itemCellNib, forCellReuseIdentifier: "itemCell")
    
    emptyStateLabel.textColor = UIColor.h5Color()
    
    totalPriceLabel.font = UIFont.monospacedDigitSystemFontOfSize(22, weight: UIFontWeightBold)
    
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
    reloadData()
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func reloadData() {
    items = OrderManager.currentOrder.items
    tableView.reloadData()
    totalPriceLabel.text = "\(OrderManager.currentOrder.totalPrice.format()) р."
  }
  
  //MARK: - Actions 
  
  @IBAction func clearButtonAction() {
    OrderManager.currentOrder.clearOrder()
    Client.currentClient = nil
    tableView.reloadData()
  }
  
  @IBAction func checkoutButtonAction() {
    presentAlertWithMessage("Оплата")
  }
}

extension CheckViewController: UITableViewDataSource {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = items.count
    
    if count == 0 {
      checkoutButtonView.hidden = true
      tableView.hidden = true
      clearOrderButton.hidden = true
      emptyStateView.hidden = false
    } else {
      checkoutButtonView.hidden = false
      tableView.hidden = false
      clearOrderButton.hidden = false
      emptyStateView.hidden = true
    }
    
    return count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let orderItem = items[indexPath.row]
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
