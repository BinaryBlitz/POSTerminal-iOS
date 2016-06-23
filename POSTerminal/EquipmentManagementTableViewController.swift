import UIKit
import PureLayout

class EquipmentManagementTableViewController: UITableViewController {
  
  @IBOutlet weak var balanceLabel: UILabel!
  
  @IBOutlet weak var checksSumLabel: UILabel!
  @IBOutlet weak var ordersSumLabel: UILabel!
  
  var activityIndicator: UIActivityIndicatorView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    balanceLabel.text = Settings.sharedInstance.cashBalance.format()
    checksSumLabel.text = Settings.sharedInstance.checksSum.format()
    ordersSumLabel.text = Settings.sharedInstance.ordersSum.format()
    
    if let uuid = uuid {
      let footerLabel = UILabel()
      footerLabel.text = uuid
      footerLabel.textAlignment = .Center
      let footerView = UIView()
      footerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 70)
      footerView.addSubview(footerLabel)
      footerLabel.autoPinEdgesToSuperviewEdges()
      tableView.tableHeaderView = footerView
    }
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(finishMenuUpdate), name: reloadMenuNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func finishMenuUpdate() {
    hideActivityIndicator()
    presentAlertWithMessage("Меню обновлено!")
  }
  
  //MARK: - Indicator methods
  
  func showActivityIndicator() {
    tableView.addSubview(activityIndicator)
    activityIndicator.autoCenterInSuperview()
    activityIndicator.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
    activityIndicator.hidden = false
    activityIndicator.startAnimating()
  }
  
  func hideActivityIndicator() {
    activityIndicator.stopAnimating()
    activityIndicator.removeFromSuperview()
    activityIndicator.hidden = true
  }
  
  //MARK: - Actions
  
  @IBAction func updateMenu() {
    NSNotificationCenter.defaultCenter().postNotificationName(updateMenuNotification, object: nil)
    showActivityIndicator()
  }
  
  @IBAction func openDay() {
    var sendCommands = 0
    
    showActivityIndicator()
    ServerManager.sharedManager.openDay { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена открыта")
          self.hideActivityIndicator()
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithTitle("Ошибка", andMessage: "Не удалсь открыть смену в базе оборудования")
        self.hideActivityIndicator()
      }
    }

    ServerManager.sharedManager.openDayInWP { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена открыта")
          self.hideActivityIndicator()
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithTitle("Ошибка", andMessage: "Не удалсь открыть смену в базе рабочего места")
        self.hideActivityIndicator()
      }
    }
  }
  
  @IBAction func closeDay() {
    var sendCommands = 0
    showActivityIndicator()
    ServerManager.sharedManager.printZReport { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена закрыта!")
          self.hideActivityIndicator()
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось закрыть смену в базе оборудования")
        self.hideActivityIndicator()
      }
    }
    
    ServerManager.sharedManager.printZReportInWP { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена закрыта!")
          self.hideActivityIndicator()
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось закрыть смену в базе рабочего места")
        self.hideActivityIndicator()
      }
    }
  }
  
  @IBAction func printXReport() {
    showActivityIndicator()
    ServerManager.sharedManager.printXReport { (response) in
      switch response.result {
      case .Success(_):
        self.presentAlertWithMessage("Отчет отправлен на печать")
        self.hideActivityIndicator()
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось напечатать отчет")
        self.hideActivityIndicator()
      }
    }
  }
  
  @IBAction func encash() {
    
  }
}
