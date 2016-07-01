import UIKit
import BCColor
import SwiftSpinner

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
  
  // Discounts
  @IBOutlet weak var discountsSumTextField: UITextField!
  @IBOutlet weak var discountCategoryTextField: UITextField!
  
  @IBOutlet weak var paymentMethodSwitch: UISwitch!
  
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
    paymentMethodSwitch.on = !Settings.sharedInstance.isCashless
    
    discountCategoryTextField.text = settings.discountCategoryName
    discountsSumTextField.text = settings.discountsBalance.format()
    
    paymentMethodSwitch.addTarget(self, action: #selector(updatePayemntMethod), forControlEvents: .ValueChanged)
  }
  
  //MARK: - Actions
  
  @IBAction func saveButtonAction() {
    view.endEditing(true)
    
    let colorsManager = ColorsManager.sharedManager
    if let hexString = colorTextField.text, color = UIColor.colorWithHex(hexString) {
      Settings.sharedInstance.baseColorHex = hexString
      colorsManager.baseColor = color
    } else if colorTextField.text == nil || colorTextField.text == "" {
      Settings.sharedInstance.baseColorHex = nil
      colorsManager.baseColor = colorsManager.defaultColor
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
    
    if let balanceString = discountsSumTextField.text, balance = Double(balanceString) {
      Settings.sharedInstance.discountsBalance = balance
    }
    
    if let discountCategoryName = discountCategoryTextField.text where discountCategoryName != "" {
      Settings.sharedInstance.discountCategoryName = discountCategoryName
    }
    
    Settings.saveToUserDefaults()
    
    presentAlertWithMessage("Настройки сохранены!")
  }
  
  func updatePayemntMethod() {
    Settings.sharedInstance.isCashless = !paymentMethodSwitch.on
    Settings.saveToUserDefaults()
    OrderManager.currentOrder.clearOrder()
    ClientManager.currentClient = nil
    NSNotificationCenter.defaultCenter().postNotificationName(newItemNotification, object: nil)
    NSNotificationCenter.defaultCenter().postNotificationName(clientUpdatedNotification, object: nil)
  }
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func checkConnectionButtonAction() {
    var sentRequests = 0
    
    SwiftSpinner.show("Проверка соединения")
    ServerManager.sharedManager.checkConnectionInEQ { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentRequests += 1
          if sentRequests == 2 {
            SwiftSpinner.show("Обе базы подключены", animated: false).addTapHandler({ 
              SwiftSpinner.hide()
              }, subtitle: "Нажмите, чтобы закрыть")
          }
        case .Failure(let error):
          print(error)
          SwiftSpinner.show("Не удалось подключиться к базе оборудования", animated: false).addTapHandler({
            SwiftSpinner.hide()
            }, subtitle: "Нажмите, чтобы закрыть")
        }
      }
    }
    
    ServerManager.sharedManager.checkConnectionInWP { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          sentRequests += 1
          if sentRequests == 2 {
            SwiftSpinner.show("Обе базы подключены", animated: false).addTapHandler({ 
              SwiftSpinner.hide()
              }, subtitle: "Нажмите, чтобы закрыть")
          }
        case .Failure(let error):
          print(error)
          SwiftSpinner.show("Не удалось подключиться к базе рабочего места", animated: false).addTapHandler({
            SwiftSpinner.hide()
            }, subtitle: "Нажмите, чтобы закрыть")
        }
      }
    }
  }
  
  @IBAction func registerDevice() {
    if let host = RedSocketManager.sharedInstance().ipAddress() {
      let callbackURL = "http://\(host):9080/codes"
      print(callbackURL)
      SwiftSpinner.show("Регистрация терминала")
      ServerManager.sharedManager.registerDeviceWithCallbackURL(callbackURL) { (response) in
        dispatch_async(dispatch_get_main_queue()) {
          switch response.result {
          case .Success(_):
            SwiftSpinner.show("Успешно!", animated: false).addTapHandler({
              SwiftSpinner.hide()
              }, subtitle: "Нажмите, чтобы закрыть")
          case .Failure(let error):
            print(error)
            SwiftSpinner.show("Не удалось", animated: false).addTapHandler({
              SwiftSpinner.hide()
              }, subtitle: "Нажмите, чтобы закрыть")
          }
        }
      }
    } else {
      presentAlertWithMessage("Не удалось зарегистрировать мобильный терминал")
    }
  }
}
