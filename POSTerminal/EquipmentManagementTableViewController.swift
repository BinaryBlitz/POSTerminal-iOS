import UIKit

class EquipmentManagementTableViewController: UITableViewController {
  
  @IBOutlet weak var balanceLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    balanceLabel.text = String(Settings.sharedInstance.cashBalance)
  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func updateMenu() {
    NSNotificationCenter.defaultCenter().postNotificationName(updateMenuNotification, object: nil)
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
