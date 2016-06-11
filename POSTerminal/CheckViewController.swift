import UIKit

protocol CheckViewControllerDelegate: class {
  func didTouchCheckoutButton()
}

class CheckViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var clearOrderButton: UIButton!
  @IBOutlet weak var clientInfoCard: CardView!
  @IBOutlet weak var checkoutButtonView: CardView!
  @IBOutlet weak var checkoutButton: UIButton!
  
  @IBOutlet weak var clientNameLabel: UILabel!
  @IBOutlet weak var clientBalanceLabel: UILabel!
  @IBOutlet weak var clientPhotoImageView: UIImageView!
  
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  
  @IBOutlet weak var totalPriceLabel: UILabel!
  
  weak var delegate: CheckViewControllerDelegate?
  
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
    
    reloadClientInfo()
    
    clearOrderButton.tintColor = UIColor.h3Color()
    
    clientInfoCard.backgroundColor = UIColor.whiteColor()
    checkoutButtonView.backgroundColor = UIColor.elementsAndH1Color()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadData), name: newItemNotification, object: nil)
    reloadData()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadClientInfo), name: clientUpdatedNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func reloadClientInfo() {
    print("reload client")
    
    if let client = Client.currentClient {
      clientNameLabel.text = client.name
      clientBalanceLabel.hidden = false
      clientBalanceLabel.text = "Баланс: \(client.balance) р."
    } else if let identity = Client.currentClientIdetity {
      ServerManager.sharedManager.getInfoFor(identity) { (response) in
        print(response)
      }
    } else {
      clientNameLabel.text = "Новый клиент"
      clientBalanceLabel.hidden = true
    }
  }
  
  func reloadData() {
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
    } else {
      items = OrderManager.currentOrder.items
      tableView.reloadData()
    }
    
    totalPriceLabel.text = "\(OrderManager.currentOrder.totalPrice.format()) р."
  }
  
  func scrollToBottom() {
    if tableView.numberOfRowsInSection(0) > 0 {
      let lastCellRowNumber = tableView.numberOfRowsInSection(0) - 1
      tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: lastCellRowNumber, inSection: 0), atScrollPosition: .Bottom, animated: true)
    }
  }
  
  //MARK: - Actions 
  
  @IBAction func clearButtonAction() {
    OrderManager.currentOrder.clearOrder()
    items = []
    Client.currentClient = nil
    tableView.reloadData()
  }
  
  @IBAction func checkoutButtonAction() {
    delegate?.didTouchCheckoutButton()
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
