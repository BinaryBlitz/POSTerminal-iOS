import UIKit
import RealmSwift

let updateMenuNotification = "updateMenuNotification"


class BaseViewController: UIViewController {
  
  @IBOutlet weak var toolBarView: UIView!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var settingsButton: UIButton!
  var menuNavigationController: UINavigationController?
  
  @IBOutlet weak var menuPathStackView:  UIStackView!
  
  @IBOutlet weak var paymentHeaderView: UIView!
  
  private var menuPath = [String]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    RedSocketManager.sharedInstance().setDelegate(self)
    
    paymentHeaderView.backgroundColor = UIColor.elementsAndH1Color()
    
    backButton.enabled = false
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
    refresh()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refresh), name: updateMenuNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  //MARK: - Refresh
  
  func refresh() {
    ServerManager.sharedManager.getMenu { (response) in
      switch response.result {
      case .Success(let menu):
        let realm = try! Realm()
        try! realm.write {
          realm.delete(realm.objects(Product))
          realm.add(menu)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(reloadMenuNotification, object: nil)
      case .Failure(let error):
        print("error: \(error)")
      }
    }
  }
  
  //MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    guard let identifier = segue.identifier else { return }
    
    switch identifier {
    case "menu":
      menuNavigationController = segue.destinationViewController as? UINavigationController
      if let menuController = menuNavigationController?.viewControllers.first as? MenuCollectionViewController {
        menuController.delegate = self
        menuController.navigationProvider = self
      }
    case "check":
      let checkViewController = segue.destinationViewController as! CheckViewController
      checkViewController.delegate = self
    default:
      break
    }
  }
  
  private func openSettings() {
    let password = NSBundle.mainBundle().objectForInfoDictionaryKey("SettingsPassword") as! String
    let alert = UIAlertController(title: "Настройки", message: "Введите пароль для доступа к настройкам", preferredStyle: .Alert)
    alert.addTextFieldWithConfigurationHandler { (textField) in
      textField.placeholder = "Пароль"
      textField.secureTextEntry = true
    }
    
    alert.addAction(UIAlertAction(title: "Отмена", style: .Cancel, handler: nil))
    
    alert.addAction(UIAlertAction(title: "Продолжить", style: .Default, handler: { (_) in
      let passwordField = alert.textFields![0]
      if passwordField.text == password {
        self.performSegueWithIdentifier("settings", sender: self)
      } else {
        self.presentAlertWithMessage("Неверный пароль")
      }
    }))
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  //MARK: - Tools
  
  private func checkBackButtonState() {
    if let navigationController = menuNavigationController {
      backButton.enabled = navigationController.viewControllers.count > 1
    }
  }
  
  //MARK: - Path stack view
  
  func createLabelWith(category: String, andColor color: UIColor) -> UILabel {
    let label = UILabel()
    label.text = category
    label.textColor = color
    label.font = UIFont.boldSystemFontOfSize(16)
    
    return label
  }
  
  func createSeparatorImageView() -> UIImageView {
    let image = UIImage(named: "PathSeparator")
    return UIImageView(image: image)
  }
  
  func clearMenuPath() {
    menuPath = []
    menuPathStackView.arrangedSubviews.forEach { (view) in
      menuPathStackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    appendCategoryToPathStack("Меню")
  }
  
  func removeTwoLastItemsFromStack() {
    let arrangedSubviews = menuPathStackView.arrangedSubviews
    guard arrangedSubviews.count > 2 else { return }
    
    let lastIndex = arrangedSubviews.count - 1
    let secondLastIndex = arrangedSubviews.count - 2 // ¯\_(ツ)_/¯
    let lastView = arrangedSubviews[lastIndex]
    let secondLastView = arrangedSubviews[secondLastIndex]
    menuPathStackView.removeArrangedSubview(lastView)
    menuPathStackView.removeArrangedSubview(secondLastView)
    lastView.removeFromSuperview()
    secondLastView.removeFromSuperview()
    
    if let lastLabel = menuPathStackView.arrangedSubviews.last as? UILabel {
      lastLabel.textColor = UIColor.whiteColor()
    }
  }
  
  func appendCategoryToPathStack(level: String) {
    menuPath.append(level)
    
    if menuPathStackView.arrangedSubviews.count == 0 {
      menuPathStackView.addArrangedSubview(createLabelWith(level, andColor: UIColor.whiteColor()))
      return
    }
    
    menuPathStackView.arrangedSubviews.forEach { (view) in
      if let label = view as? UILabel {
        label.textColor = UIColor.h2Color()
      }
    }
    
    menuPathStackView.addArrangedSubview(createSeparatorImageView())
    menuPathStackView.addArrangedSubview(createLabelWith(level, andColor: UIColor.whiteColor()))
  }
  
  func popLastCategoryFromPathStack() {
    switch menuPath.count {
    case 0:
      break
    case 1:
      menuPath.popLast()
      removeTwoLastItemsFromStack()
    default:
      menuPath.popLast()
      removeTwoLastItemsFromStack()
    }
  }
  
  //MARK: - Actions 
  
  @IBAction func paymentBackButton() {
    UIView.animateWithDuration(0.3, animations: { 
        self.paymentHeaderView.alpha = 0
      }) { (finished) in
        self.paymentHeaderView.hidden = true
    }
    
    backButtonAction()
    NSNotificationCenter.defaultCenter().postNotificationName(CheckoutViewController.Notifications.PaymentFinished, object: nil)
  }
  
  @IBAction func backButtonAction() {
    menuNavigationController?.popViewControllerAnimated(false)
    checkBackButtonState()
    popLastCategoryFromPathStack()
  }
  
  @IBAction func homeButtonAction() {
    menuNavigationController?.popToRootViewControllerAnimated(false)
    checkBackButtonState()
    clearMenuPath()
  }
  
  @IBAction func settingsButtonAction() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    alert.addAction(UIAlertAction(title: "Управление кассой", style: .Default, handler: { (_) in
      self.performSegueWithIdentifier("eqManagment", sender: self)
    }))
    alert.addAction(UIAlertAction(title: "Настройки", style: .Default, handler: { (_) in
      self.openSettings()
    }))
    
    alert.popoverPresentationController?.sourceView = view
    alert.popoverPresentationController?.sourceRect = settingsButton.frame
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
}

extension BaseViewController: MenuCollectionDelegate {
  
  func menuCollection(collection: MenuCollectionViewController, didSelectProdict product: Product) {
    checkBackButtonState()
    
    if product.type == .Group {
      let category = product.name
      if let lastCategory = menuPath.last where lastCategory != category {
        appendCategoryToPathStack(category)
      } else if menuPath.count == 0 {
        appendCategoryToPathStack(category)
      }
    }
  }
  
}

extension BaseViewController: UIPopoverPresentationControllerDelegate { }

extension BaseViewController: RedSocketManagerDelegate {
  
  func cableConnected(protocol: String!) {
    presentAlertWithMessage("Кабель подключен")
  }
  
  func cableDisconnected() {
    presentAlertWithMessage("Кабель отключен")
  }
  
}

extension BaseViewController: MenuNavigationProvider {
  
  func popViewController() {
    backButtonAction()
  }
  
  func popToRootViewController() {
    homeButtonAction()
  }
  
}

extension BaseViewController: CheckViewControllerDelegate {
  
  func didTouchCheckoutButton() {
    paymentHeaderView.alpha = 0
    paymentHeaderView.hidden = false
    UIView.animateWithDuration(0.3) { 
      self.paymentHeaderView.alpha = 1
    }
    
    homeButtonAction()
    let checkoutViewController = storyboard!.instantiateViewControllerWithIdentifier("Payment")
    menuNavigationController?.pushViewController(checkoutViewController, animated: true)
  }
  
}
