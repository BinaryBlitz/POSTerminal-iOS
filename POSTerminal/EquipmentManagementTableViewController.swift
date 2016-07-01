import UIKit
import PureLayout
import SwiftSpinner

class EquipmentManagementTableViewController: UITableViewController {
  
  @IBOutlet weak var balanceLabel: UILabel!
  
  
  @IBOutlet weak var rfidSumLabel: UILabel!
  @IBOutlet weak var checksSumLabel: UILabel!
  @IBOutlet weak var ordersSumLabel: UILabel!
  
  var activityIndicator: UIActivityIndicatorView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    balanceLabel.text = Settings.sharedInstance.cashBalance.format()
    checksSumLabel.text = Settings.sharedInstance.checksSum.format()
    ordersSumLabel.text = Settings.sharedInstance.ordersSum.format()
    rfidSumLabel.text = Settings.sharedInstance.rfidSum.format()
    
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
    
    if let host = RedSocketManager.sharedInstance().ipAddress() {
      let urlLabel = UILabel()
      urlLabel.text = "http://\(host):9080/codes"
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
    hideActivityIndicator("Меню обновлено!")
  }
  
  //MARK: - Indicator methods
  
  //TODO: rename me pls
  func showActivityIndicator(message: String) {
    SwiftSpinner.show(message)
  }
  
  //TODO: and me
  func hideActivityIndicator(message: String) {
    SwiftSpinner.show(message, animated: false).addTapHandler({
        SwiftSpinner.hide()
      }, subtitle: "Нажмите, чтобы закрыть")
  }
  
  //MARK: - Actions
  
  @IBAction func updateMenu() {
    NSNotificationCenter.defaultCenter().postNotificationName(updateMenuNotification, object: nil)
    showActivityIndicator("Обновление меню")
  }
  
  @IBAction func openDay() {
    var sendCommands = 0
    
    showActivityIndicator("Открытие смены")
    ServerManager.sharedManager.openDay { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sendCommands += 1
          if sendCommands == 2 {
            self.hideActivityIndicator("Кассовая смена открыта")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалсь открыть смену в базе оборудования")
        }
      }
    }

    ServerManager.sharedManager.openDayInWP { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sendCommands += 1
          if sendCommands == 2 {
            self.hideActivityIndicator("Кассовая смена открыта")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалсь открыть смену в базе рабочего места")
        }
      }
    }
  }
  
  @IBAction func closeDay() {
    var sendCommands = 0
    showActivityIndicator("Закрытие смены")
    ServerManager.sharedManager.printZReport { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sendCommands += 1
          if sendCommands == 2 {
            self.hideActivityIndicator("Кассовая смена закрыта!")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалось закрыть смену в базе оборудования")
        }
      }
    }
    
    ServerManager.sharedManager.printZReportInWP { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sendCommands += 1
          if sendCommands == 2 {
            self.hideActivityIndicator("Кассовая смена закрыта!")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалось закрыть смену в базе рабочего места")
        }
      }
    }
  }
  
  @IBAction func printXReport() {
    showActivityIndicator("Печать отчета")
    ServerManager.sharedManager.printXReport { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          self.hideActivityIndicator("Отчет отправлен на печать")
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалось напечатать отчет")
        }
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
    showActivityIndicator("Инкасcация")
    ServerManager.sharedManager.printXReport { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          self.sendEncashRequest(sum, type: type)
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Не удалось напечатать отчет")
        }
      }
    }
  }
  
  private func sendEncashRequest(sum: Double, type: EncashType) {
    var sentCommands = 0
    ServerManager.sharedManager.encash(sum, type: type) { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentCommands += 1
          if sentCommands == 2 {
            self.updateBalance(sum, forEncash: type)
            self.balanceLabel.text = Settings.sharedInstance.cashBalance.format()
            self.hideActivityIndicator("Инкассация успешно проведена!")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Ошибка при регистрации инкассации в базе оборудования")
        }
      }
    }
    
    ServerManager.sharedManager.encashInWP(sum, type: type) { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentCommands += 1
          if sentCommands == 2 {
            self.updateBalance(sum, forEncash: type)
            self.balanceLabel.text = Settings.sharedInstance.cashBalance.format()
            self.hideActivityIndicator("Инкассация успешно проведена!")
          }
        case .Failure(let error):
          print(error)
          self.hideActivityIndicator("Ошибка при регистрации инкассации в базе рабочего места")
        }
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
