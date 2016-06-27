import UIKit

class CheckViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var clearOrderButton: UIButton!
  @IBOutlet weak var clientInfoCard: CardView!
  @IBOutlet weak var checkoutButtonView: CardView!
  @IBOutlet weak var checkoutButton: UIButton!
  
  @IBOutlet weak var changeClientButton: UIButton!
  
  @IBOutlet weak var clientNameLabel: UILabel!
  @IBOutlet weak var clientBalanceLabel: UILabel!
  @IBOutlet weak var clientPhotoImageView: UIImageView!
  
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  
  @IBOutlet weak var totalPriceLabel: UILabel!
  
  var selectedCellIndexPath: NSIndexPath?
  
  var items = [OrderItem]()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    changeClientButton.hidden = true
    
    view.backgroundColor = UIColor.whiteColor()
    tableView.backgroundColor =  UIColor.whiteColor()
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableFooterView = UIView()
    
    let itemCellNib = UINib(nibName: String(CheckItemTableViewCell), bundle: nil)
    tableView.registerNib(itemCellNib, forCellReuseIdentifier: "itemCell")
    
    emptyStateLabel.textColor = UIColor.h5Color()
    
    totalPriceLabel.font = UIFont.monospacedDigitSystemFontOfSize(22, weight: UIFontWeightBold)
    
    clientNameLabel.textColor = UIColor.h4Color()
    clientBalanceLabel.textColor = UIColor.h5Color()
    
    reloadClientInfo()
    
    clearOrderButton.tintColor = UIColor.h3Color()
    
    clientInfoCard.backgroundColor = UIColor.whiteColor()
    checkoutButtonView.backgroundColor = UIColor.elementsAndH1Color()
    
    totalPriceLabel.text = "\(OrderManager.currentOrder.totalPrice.format()) р."
    
    clientInfoCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(printClientBalance)))
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadData(_:)), name: newItemNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadClientInfo), name: clientUpdatedNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(endCheckout), name: endCheckoutNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateColors), name: UpdateColorsNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func updateColors() {
    reloadCheckoutButton()
    tableView.reloadData()
  }
  
  func printClientBalance() {
    guard let client = ClientManager.currentClient else { return }
    ServerManager.sharedManager.printClientBalance(client) { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          self.presentAlertWithMessage("Печать баланса")
        case .Failure(let error):
          print(error)
        }
      }
    }
  }
  
  func endCheckout() {
    reloadData()
    view.userInteractionEnabled = true
    reloadClientInfo()
  }
  
  func reloadClientInfo() {
    if let client = ClientManager.currentClient {
      clientNameLabel.text = client.name
      clientBalanceLabel.hidden = false
      clientBalanceLabel.text = "Баланс: \(client.balance.format()) р."
      changeClientButton.hidden = false
    } else {
      clientNameLabel.text = "Новый клиент"
      clientBalanceLabel.hidden = true
      changeClientButton.hidden = true
    }
    
    reloadCheckoutButton()
  }
  
  func reloadCheckoutButton() {
    totalPriceLabel.text = "\(OrderManager.currentOrder.totalPrice.format()) р."
    if let client = ClientManager.currentClient where client.balance >= OrderManager.currentOrder.totalPrice {
      checkoutButton.enabled = true
      checkoutButtonView.backgroundColor = UIColor.elementsAndH1Color()
    } else {
      checkoutButton.enabled = false
      checkoutButtonView.backgroundColor = UIColor.h5Color()
    }
  }
  
  func reloadData(notification: NSNotification? = nil) {
    selectedCellIndexPath = nil
    let newItemsList = OrderManager.currentOrder.items
    if newItemsList.count > items.count && items.count > 0 {
      let numberOfNewItems = newItemsList.count - items.count
      let indexPathsToUpdate = Array(count: numberOfNewItems, repeatedValue: NSIndexPath())
        .enumerate().map { (index, indexPath) -> NSIndexPath in
          return NSIndexPath(forRow: newItemsList.count - index - 1, inSection: 0)
      }
      self.items = newItemsList
      tableView.beginUpdates()
      tableView.insertRowsAtIndexPaths(indexPathsToUpdate, withRowAnimation: UITableViewRowAnimation.Fade)
      tableView.endUpdates()
      scrollToBottom()
    } else if let product = notification?.userInfo?["product"] as? Product {
      let productIndex = items.indexOf { item -> Bool in
        return item.product.productId == product.productId
      }
      if let index = productIndex {
        items = OrderManager.currentOrder.items
        tableView.reloadData()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
      } else {
        items = OrderManager.currentOrder.items
        tableView.reloadData()
      }
    } else {
      items = OrderManager.currentOrder.items
      tableView.reloadData()
    }
    
    reloadCheckoutButton()
  }
  
  func scrollToBottom() {
    if tableView.numberOfRowsInSection(0) > 0 {
      let lastCellRowNumber = tableView.numberOfRowsInSection(0) - 1
      tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: lastCellRowNumber, inSection: 0), atScrollPosition: .Bottom, animated: true)
    }
  }
  
  //MARK: - Actions 
  
  @IBAction func clearButtonAction() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    alert.addAction(UIAlertAction(title: "Очистить", style: .Destructive, handler: { (action) in
      OrderManager.currentOrder.clearOrder()
      self.items = []
      ClientManager.currentClient = nil
      self.tableView.reloadData()
      self.reloadClientInfo()
    }))
    alert.addAction(UIAlertAction(title: "Отмена", style: .Default, handler: nil))
    
    alert.popoverPresentationController?.sourceView = clearOrderButton
    alert.popoverPresentationController?.sourceRect = clearOrderButton.frame
   
    presentViewController(alert, animated: true, completion: nil)
  }
  
  @IBAction func checkoutButtonAction() {
    selectedCellIndexPath = nil
    tableView.reloadData()
    view.userInteractionEnabled = false
    NSNotificationCenter.defaultCenter().postNotificationName(startCheckoutNotification, object: nil)
  }
  
  @IBAction func changeClientButtonAction(button: UIButton) {
    ClientManager.currentClient = nil
    button.hidden = true
    reloadClientInfo()
  }
}

//MARK: - UITableViewDataSource

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
    cell.delegate = self
    
    if let selectedIndexPath = selectedCellIndexPath where selectedIndexPath == indexPath {
      cell.state = .Editing
    } else {
      cell.state = .Normal
    }
    
    return cell
  }
  
}

//MARK: - UITableViewDelegate

extension CheckViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 75
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .Default, title: "Удалить") { (action, indexPath) in
      self.items.removeAtIndex(indexPath.row)
      OrderManager.currentOrder.items = self.items
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
      self.reloadData()
    }
    
    return [deleteAction]
  }
  
  func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
    if let selectedIndexPath = selectedCellIndexPath where selectedIndexPath == indexPath {
      if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CheckItemTableViewCell {
        cell.state = .Normal
        selectedCellIndexPath = nil
      }
    }
  }
}

//MARK: - CheckItemCellDelegate

extension CheckViewController: CheckItemCellDelegate {
  
  func didTouchPlusButtonIn(cell: CheckItemTableViewCell) {
    let indexPath = tableView.indexPathForCell(cell)!
    let item = items[indexPath.row]
    item.inrementQuantity()
    tableView.reloadData()
    reloadCheckoutButton()
  }
  
  func didTouchMinusButtonIn(cell: CheckItemTableViewCell) {
    let indexPath = tableView.indexPathForCell(cell)!
    let item = items[indexPath.row]
    item.decrementQuantity()
    tableView.reloadData()
    reloadCheckoutButton()
  }
  
  func didUpdateStateFor(cell: CheckItemTableViewCell) {
    switch cell.state {
    case .Normal:
      selectedCellIndexPath = nil
    case .Editing:
      let indexPath = tableView.indexPathForCell(cell)!
      selectedCellIndexPath = indexPath
    }
    tableView.reloadData()
  }
  
}
