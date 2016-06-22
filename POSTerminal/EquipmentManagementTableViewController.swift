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
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(hideActivityIndicator), name: reloadMenuNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func hideActivityIndicator() {
    activityIndicator.stopAnimating()
    activityIndicator.removeFromSuperview()
    activityIndicator.hidden = true
    presentAlertWithMessage("Меню обновлено!")
  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func updateMenu() {
    NSNotificationCenter.defaultCenter().postNotificationName(updateMenuNotification, object: nil)
    tableView.addSubview(activityIndicator)
    activityIndicator.autoCenterInSuperview()
    activityIndicator.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
    activityIndicator.hidden = false
    activityIndicator.startAnimating()
  }
  
  @IBAction func openDay() {
    var sendCommands = 0
    
    ServerManager.sharedManager.openDay { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена открыта")
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithTitle("Ошибка", andMessage: "Не удалсь открыть смену в базе оборудования")
      }
    }

    ServerManager.sharedManager.openDayInWP { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена открыта")
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithTitle("Ошибка", andMessage: "Не удалсь открыть смену в базе рабочего места")
      }
    }
  }
  
  @IBAction func closeDay() {
    var sendCommands = 0
    ServerManager.sharedManager.printZReport { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена закрыта!")
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось закрыть смену в базе оборудования")
      }
    }
    
    ServerManager.sharedManager.printZReportInWP { (response) in
      switch response.result {
      case .Success(_):
        sendCommands += 1
        if sendCommands == 2 {
          self.presentAlertWithMessage("Кассовая смена закрыта!")
        }
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось закрыть смену в базе рабочего места")
      }
    }
  }
  
  @IBAction func printXReport() {
    ServerManager.sharedManager.printXReport { (response) in
      switch response.result {
      case .Success(_):
        self.presentAlertWithMessage("Отчет отправлен на печать")
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось напечатать отчет")
      }
    }
  }
  
  @IBAction func encash() {
    
  }
}
