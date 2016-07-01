import UIKit
import RealmSwift
import PureLayout

let updateMenuNotification = "updateMenuNotification"

let endCheckoutNotification = "endCheckoutNotification"
let startCheckoutNotification = "startCheckoutNotification"

let presentViewControllerNotification = "presentViewControllerNotification"

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
    
    backButton.setImage(UIImage(named: "Back")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    backButton.setImage(UIImage(named: "Back")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Disabled)
    backButton.tintColor = UIColor.h2Color()
    
    backButton.enabled = false
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
    clearMenuPath()
//    refresh()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refresh), name: updateMenuNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(startCheckout), name: startCheckoutNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(endCheckout), name: endCheckoutNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(presentNotification(_:)), name: presentViewControllerNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateColors), name: UpdateColorsNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func updateColors() {
    checkBackButtonState()
    toolBarView.backgroundColor = UIColor.elementsAndH1Color()
    paymentHeaderView.backgroundColor = UIColor.elementsAndH1Color()
    homeButtonAction()
  }
  
  func presentNotification(notification: NSNotification? = nil) {
    guard let viewController = notification?.userInfo?["viewController"] as? UIViewController else { return }
    presentViewController(viewController, animated: true, completion: nil)
  }
  
  func present(viewController: UIViewController) {
    
  }
  
  //MARK: - Checkout
  
  func startCheckout() {
    let paymentHeaderFrame = paymentHeaderView.frame
    paymentHeaderView.alpha = 0
    paymentHeaderView.frame = CGRect(
        origin: CGPoint(x: -(paymentHeaderFrame.size.width), y: paymentHeaderFrame.origin.y),
        size: paymentHeaderFrame.size
    )
    paymentHeaderView.hidden = false
    UIView.animateWithDuration(0.3) {
      self.paymentHeaderView.frame = paymentHeaderFrame
      self.paymentHeaderView.alpha = 1
    }
    
    homeButtonAction()
    let checkoutViewController = storyboard!.instantiateViewControllerWithIdentifier("Payment")
    menuNavigationController?.pushViewController(checkoutViewController, animated: true)
  }
  
  func endCheckout() {
    menuNavigationController?.popViewControllerAnimated(true)
    UIView.animateWithDuration(0.2, animations: {
        self.paymentHeaderView.alpha = 0
      }) { (finished) in
        self.paymentHeaderView.hidden = true
    }
  }
  
  //MARK: - Refresh
  
  func refresh() {
    ServerManager.sharedManager.getMenu { (response) in
      dispatch_async(dispatch_get_main_queue()) {
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
    default:
      break
    }
  }
  
  private func openSettings() {
    let password = NSBundle.mainBundle().objectForInfoDictionaryKey("SettingsPassword") as! String
    if password == "" {
      performSegueWithIdentifier("settings", sender: self)
    }
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
      if backButton.enabled {
        backButton.setImage(UIImage(named: "Back")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        backButton.tintColor = UIColor.whiteColor()
      } else {
        backButton.setImage(UIImage(named: "Back")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Disabled)
        backButton.tintColor = UIColor.h2Color()
      }
    }
  }
  
  //MARK: - Path stack view
  
  func createButtonWith(category: String, andColor color: UIColor) -> UIButton {
    let button = UIButton()
    button.setTitle(category, forState: .Normal)
    button.setTitleColor(color, forState: .Normal)
    button.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
    button.autoSetDimension(ALDimension.Height, toSize: 60)
    button.addTarget(self, action: #selector(categoryButtonAction(_:)), forControlEvents: .TouchUpInside)
    
    return button
  }
  
  func categoryButtonAction(button: UIButton) {
    while let last = menuPath.last where last != button.titleLabel?.text {
      backButtonAction()
    }
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
  }
  
  func createSeparatorImageView() -> UIImageView {
    let image = UIImage(named: "PathSeparator")?.imageWithRenderingMode(.AlwaysTemplate)
    let imageView = UIImageView(image: image)
    imageView.tintColor = UIColor.h2Color()
    return imageView
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
    
    if let lastButton = menuPathStackView.arrangedSubviews.last as? UIButton {
      lastButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
  }
  
  func appendCategoryToPathStack(level: String) {
    menuPath.append(level)
    
    if menuPathStackView.arrangedSubviews.count == 0 {
      menuPathStackView.addArrangedSubview(createButtonWith(level, andColor: UIColor.whiteColor()))
      return
    }
    
    menuPathStackView.arrangedSubviews.forEach { (view) in
      if let button = view as? UIButton {
        button.setTitleColor(UIColor.h2Color(), forState: .Normal)
      }
    }
    
    menuPathStackView.addArrangedSubview(createSeparatorImageView())
    menuPathStackView.addArrangedSubview(createButtonWith(level, andColor: UIColor.whiteColor()))
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
    NSNotificationCenter.defaultCenter().postNotificationName(endCheckoutNotification, object: nil)
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
  
  func menuCollection(collection: MenuCollectionViewController, didSelectProduct product: Product) {
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
  
  func menuCollection(collection: MenuCollectionViewController, shouldSelectProduct product: Product) -> Bool {
    guard let discountCategory = Settings.sharedInstance.discountCategoryName?.lowercaseString else { return true }
    let productCategory = product.category.lowercaseString
    
    let orderManager = OrderManager.currentOrder
    
    if orderManager.items.count == 0 {
      return true
    }
   
    let discountProductsCount = orderManager.items.reduce(0) { (sum, item) -> Int in
      return sum + (item.product.category.lowercaseString == discountCategory ? 1 : 0)
    }
    
    if discountProductsCount == orderManager.items.count && productCategory != discountCategory {
      return false
    } else if discountProductsCount == 0 && productCategory == discountCategory {
      return false
    } else {
      return true
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
