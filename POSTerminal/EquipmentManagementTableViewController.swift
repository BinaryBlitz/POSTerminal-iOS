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
    
    let stackView = UIStackView()
    stackView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100)
    stackView.alignment = .Center
    stackView.distribution = .FillProportionally
    stackView.axis = .Vertical
    if let uuid = uuid {
      let uuidLabel = UILabel()
      uuidLabel.text = uuid
      uuidLabel.textAlignment = .Center
      stackView.addArrangedSubview(uuidLabel)
    }
    
    if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
        server = appDelegate.gcdWebServer where server.serverURL != nil {
      let urlLabel = UILabel()
      urlLabel.text = server.serverURL.absoluteString
      stackView.addArrangedSubview(urlLabel)
    }
    
    tableView.tableHeaderView = stackView
    
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
    let alert = UIAlertController(title: "Инкассация", message: nil, preferredStyle: .Alert)
    alert.addTextFieldWithConfigurationHandler { (textField) in
      textField.placeholder = "Сумма"
      textField.keyboardType = .NumberPad
    }
    
    alert.addAction(UIAlertAction(title: "Изъятие", style: .Default, handler: { (action) in
      guard let sumTextField = alert.textFields?.first, sumString = sumTextField.text, sum = Double(sumString) else {
        self.presentAlertWithMessage("Сумма введена неверно")
        return
      }
      
      self.encash(sum, type: .Out)
    }))
    
    alert.addAction(UIAlertAction(title: "Внесение", style: .Default, handler: { (action) in
      guard let sumTextField = alert.textFields?.first, sumString = sumTextField.text, sum = Double(sumString) else {
        self.presentAlertWithMessage("Сумма введена неверно")
        return
      }
      
      self.encash(sum, type: .In)
    }))
    
    alert.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Cancel, handler: nil))
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  private func encash(sum: Double, type: EncashType) {
    showActivityIndicator()
    ServerManager.sharedManager.printXReport { (response) in
      switch response.result {
      case .Success(_):
        self.hideActivityIndicator()
        self.sendEncashRequest(sum, type: type)
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Не удалось напечатать отчет")
        self.hideActivityIndicator()
      }
    }
  }
  
  private func sendEncashRequest(sum: Double, type: EncashType) {
    var sentCommands = 0
    ServerManager.sharedManager.encash(sum, type: type) { (response) in
      switch response.result {
      case .Success(_):
        sentCommands += 1
        if sentCommands == 2 {
          self.hideActivityIndicator()
          self.updateBalance(sum, forEncash: type)
          self.balanceLabel.text = Settings.sharedInstance.cashBalance.format()
          self.presentAlertWithMessage("Инкассация успешно проведена!")
        }
      case .Failure(let error):
        print(error)
        self.hideActivityIndicator()
        self.presentAlertWithMessage("Ошибка при регистрации инкассации в базе оборудования")
      }
    }
    
    ServerManager.sharedManager.encashInWP(sum, type: type) { (response) in
      switch response.result {
      case .Success(_):
        sentCommands += 1
        if sentCommands == 2 {
          self.hideActivityIndicator()
          self.updateBalance(sum, forEncash: type)
          self.balanceLabel.text = Settings.sharedInstance.cashBalance.format()
          self.presentAlertWithMessage("Инкассация успешно проведена!")
        }
      case .Failure(let error):
        print(error)
        self.hideActivityIndicator()
        self.presentAlertWithMessage("Ошибка при регистрации инкассации в базе рабочего места")
      }
    }
  }
  
  func updateBalance(sum: Double, forEncash type: EncashType) {
    switch type {
    case .In:
      Settings.sharedInstance.cashBalance += sum
    case .Out:
      Settings.sharedInstance.cashBalance -= sum
    }
    
    Settings.saveToUserDefaults()
  }
}
