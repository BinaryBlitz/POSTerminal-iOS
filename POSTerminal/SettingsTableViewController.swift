import UIKit
import BCColor

class SettingsTableViewController: UITableViewController {
  
  @IBOutlet weak var colorTextField: UITextField!
  
  @IBOutlet weak var wpURLTextField: UITextField!
  @IBOutlet weak var wpUsernameTextField: UITextField!
  @IBOutlet weak var wpPasswordTextField: UITextField!

  @IBOutlet weak var eqURLTextField: UITextField!
  @IBOutlet weak var eqUsernameTextField: UITextField!
  @IBOutlet weak var eqPasswordTextField: UITextField!
  
  @IBOutlet weak var cashBalanceTextField: UITextField!
  
  @IBOutlet weak var checksSumTextField: UITextField!
  @IBOutlet weak var ordersSumTextField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let settings = Settings.sharedInstance
    
    colorTextField.text = settings.baseColorHex
    
    wpURLTextField.text = settings.wpBase?.baseURL
    wpUsernameTextField.text = settings.wpBase?.login
    wpPasswordTextField.text = settings.wpBase?.password

    eqURLTextField.text = settings.equipServ?.baseURL
    eqUsernameTextField.text = settings.equipServ?.login
    eqPasswordTextField.text = settings.equipServ?.password
    
    cashBalanceTextField.text = String(settings.cashBalance)
    
    checksSumTextField.text = settings.checksSum.format()
    ordersSumTextField.text = settings.ordersSum.format()
  }
  
  //MARK: - Actions
  
  @IBAction func saveButtonAction() {
    view.endEditing(true)
    
    if let hexString = colorTextField.text, color = UIColor.colorWithHex(hexString) {
      Settings.sharedInstance.baseColorHex = hexString
      ColorsManager.sharedManager.baseColor = color
    }
    
    if let url = wpURLTextField.text, username = wpUsernameTextField.text,
        password = wpPasswordTextField.text {
      Settings.sharedInstance.wpBase = Host(baseURL: url, login: username, password: password)
    }
    
    if let url = eqURLTextField.text, username = eqUsernameTextField.text,
        password = eqPasswordTextField.text {
      Settings.sharedInstance.equipServ = Host(baseURL: url, login: username, password: password)
    }
    
    if let balanceString = cashBalanceTextField.text, balance = Double(balanceString) {
      Settings.sharedInstance.cashBalance = balance
    }
    
    if let checksSum = checksSumTextField.text, sum = Double(checksSum) {
      Settings.sharedInstance.checksSum = sum
    }
    
    if let ordersSum = ordersSumTextField.text, sum = Double(ordersSum) {
      Settings.sharedInstance.ordersSum = sum
    }
    
    Settings.saveToUserDefaults()
    
    presentAlertWithMessage("Настройки сохранены!")
  }
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func checkConnectionButtonAction() {
    var sentRequests = 0
    
    ServerManager.sharedManager.checkConnectionInEQ { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentRequests += 1
          if sentRequests == 2 {
            self.presentAlertWithMessage("Обе базы успешно подключены!")
          }
        case .Failure(let error):
          print(error)
          self.presentAlertWithTitle("Ошибка", andMessage: "Не удалось подключиться к базе оборудования")
        }
      }
    }
    
    ServerManager.sharedManager.checkConnectionInWP { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentRequests += 1
          if sentRequests == 2 {
            self.presentAlertWithMessage("Обе базы успешно подключены!")
          }
        case .Failure(let error):
          print(error)
          self.presentAlertWithTitle("Ошибка", andMessage: "Не удалось подключиться к базе рабочего места")
        }
      }
    }
  }
  
  @IBAction func registerDevice() {
    if let host = getWiFiAddress() {
      let callbackURL = "http://\(host):9080/codes"
      print(callbackURL)
      ServerManager.sharedManager.registerDeviceWithCallbackURL(callbackURL) { (response) in
        dispatch_async(dispatch_get_main_queue()) {
          switch response.result {
          case .Success(_):
            self.presentAlertWithMessage("Мобильный терминал успешно зарегистрирован!")
          case .Failure(let error):
            print(error)
            self.presentAlertWithMessage("Не удалось зарегистрировать мобильный терминал")
          }
        }
      }
    } else {
      presentAlertWithMessage("Не удалось зарегистрировать мобильный терминал")
    }
  }
}
