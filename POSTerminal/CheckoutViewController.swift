import UIKit
import RealmSwift
import SwiftyJSON
import SwiftSpinner

class CheckoutViewController: UIViewController {
  
  enum Notifications {
    static let PaymentFinished = "PaymentFinished"
  }
  
  @IBOutlet weak var priceTitleLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var paymentTypeLabel: UILabel!
  
  var selectedPaymentType: Payment.Method = .Card

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.whiteColor()
    priceTitleLabel.textColor = UIColor.h5Color()
    priceTitleLabel.font = UIFont.boldSystemFontOfSize(18)
    priceLabel.textColor = UIColor.h4Color()
    priceLabel.font = UIFont.boldSystemFontOfSize(20)
    priceLabel.text = "\(OrderManager.currentOrder.residual.format()) р."
    
    paymentTypeLabel.tintColor = UIColor.elementsAndH1Color()
    
    if !Settings.sharedInstance.isCashless {
      paymentTypeLabel.text = "Наличные"
      selectedPaymentType = .Cash
      changePaymentMethod()
    } else {
      paymentTypeLabel.text = "Со счета"
    }
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateColors),
                                                     name: UpdateColorsNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func updateColors() {
    paymentTypeLabel.tintColor = UIColor.elementsAndH1Color()
  }
  
  //MARK: - Actions
  
  func changePaymentMethod() {
    var currentController: UIViewController?
    var viewControllerToPresent: UIViewController?
    
    switch selectedPaymentType {
    case .Card:
      let cardPaymentController = storyboard?.instantiateViewControllerWithIdentifier("CardPayment") as! CardPaymentViewController
      cardPaymentController.delegate = self
      viewControllerToPresent = cardPaymentController
      for child in childViewControllers {
        if let content = child as? CashPaymentViewController {
          currentController = content
          break
        }
      }
    case .Cash:
      let cashPayementController = storyboard?.instantiateViewControllerWithIdentifier("CashPayment") as! CashPaymentViewController
      cashPayementController.delegate = self
      viewControllerToPresent = cashPayementController
      for child in childViewControllers {
        if let content = child as? CardPaymentViewController {
          currentController = content
          break
        }
      }
    }
    
    guard let current = currentController, toPresent = viewControllerToPresent else { return }
    
    current.willMoveToParentViewController(nil)
    addChildViewController(toPresent)
    
    let duration = 0.2
    toPresent.view.frame = current.view.frame
    
    transitionFromViewController(current,
      toViewController: toPresent,
      duration: duration,
      options: UIViewAnimationOptions.TransitionCrossDissolve,
      animations: nil) { (finished) -> Void in
        if finished {
          current.removeFromParentViewController()
          toPresent.didMoveToParentViewController(self)
        }
    }
  }
  
  //MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "cardPayment" {
      let destination = segue.destinationViewController as! CardPaymentViewController
      destination.delegate = self
    }
  }
}

//MARK: - PaymentControllerDelegate

extension CheckoutViewController: PaymentControllerDelegate {
  
  func didUpdatePayments() {
    let residual = OrderManager.currentOrder.residual
    if residual == 0 {
      if Settings.sharedInstance.isCashless {
        updateClientBalanceAndFinishOrder()
      } else {
        finishOrderWithCash()
      }
    } else if residual < 0 {
      let alert = UIAlertController(title: "Сдача: \((-residual).format()) рублей", message: nil, preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: "Завершить заказ", style: .Default, handler: { (action) in
        if let lastPayment = OrderManager.currentOrder.payments.last {
          OrderManager.currentOrder.payments.removeLast()
          OrderManager.currentOrder.payments.append(Payment(amount: lastPayment.amount + residual, method: .Cash))
        }
        
        if Settings.sharedInstance.isCashless {
          self.updateClientBalanceAndFinishOrder()
        } else {
          self.finishOrderWithCash()
        }
      }))
      alert.addAction(UIAlertAction(title: "Отмена", style: .Cancel, handler: { (action) in
        if !OrderManager.currentOrder.payments.isEmpty {
          OrderManager.currentOrder.payments.removeLast()
        }
        self.didUpdatePayments()
      }))
      
      presentViewController(alert, animated: true, completion: nil)
    } else {
      priceLabel.text = "\(OrderManager.currentOrder.residual.format()) р."
    }
  }
  
  /// Process order with cash payment
  func finishOrderWithCash() {
    let manager = OrderManager.currentOrder
    let client = ClientManager.currentClient ?? Client(id: "0", code: "0", name: "Клиент", balance: 0)
    let check = Check(client: client, items: manager.items, payemnts: manager.payments)
    Settings.sharedInstance.ordersSum += manager.totalPrice
    Settings.saveToUserDefaults()
    let realm = try! Realm()
    let journalItem = JournalItem(check: check)
    journalItem.cashOnly = true
    try! realm.write {
      realm.add(journalItem)
    }
    ServerManager.sharedManager.create(check)
    ServerManager.sharedManager.printCheck(check)
    if OrderManager.currentOrder.hasDiscountItems {
      Settings.sharedInstance.discountsBalance -= OrderManager.currentOrder.totalPrice
    }
    Settings.sharedInstance.cashBalance += manager.payments.reduce(0, combine: { (sum, payment) -> Double in
      if payment.method == .Cash {
        return payment.amount
      }
      
      return 0
    })
    Settings.saveToUserDefaults()
    OrderManager.currentOrder.clearOrder()
    ClientManager.currentClient = nil
    NSNotificationCenter.defaultCenter().postNotificationName(endCheckoutNotification, object: nil)
  }
  
  /// Updates client balance for RFID users and creates check after that
  private func updateClientBalanceAndFinishOrder() {
    let manager = OrderManager.currentOrder
    guard let client = ClientManager.currentClient, identity = client.identity
        where identity.type == .BalanceData && manager.paymentType == .Balance else  {
      createCheck()
      return
    }
    
    SwiftSpinner.show("Запись данных на RFID")
    ServerManager.sharedManager.updateClientBalance(client, balance: client.balance - manager.totalPrice) { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          self.createCheck()
        case .Failure(let error):
          SwiftSpinner.hide {
            self.presentAlertWithMessage("Не удалось записать данные!")
          }
          if !OrderManager.currentOrder.payments.isEmpty {
            OrderManager.currentOrder.payments.removeLast()
          }
          self.didUpdatePayments()
          print(error)
        }
      }
    }
    
  }
  
  /// Creates check for current order and then prints it
  func createCheck() {
    let manager = OrderManager.currentOrder
    guard let client = ClientManager.currentClient else  { return }
    let check = Check(client: client, items: manager.items, payemnts: manager.payments)
    
    SwiftSpinner.show("Регистрация покупки")
    ServerManager.sharedManager.create(check) { (response) in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(let docId):
          Settings.sharedInstance.ordersSum += manager.totalPrice
          Settings.saveToUserDefaults()
          do {
            let realm = try Realm()
            let journalItem = JournalItem(check: check)
            journalItem.docId = docId
            try realm.write {
              realm.add(journalItem)
            }
            self.printCheck(check)
          } catch let error {
            print(error)
          }
        case .Failure(let error):
          SwiftSpinner.show("Не удалось зарегистрировать чек", animated: false)
          do {
            let realm = try Realm()
            let journalItem = JournalItem(check: check)
            try realm.write {
              realm.add(journalItem)
            }
            self.printCheck(check)
          } catch let error {
            print(error)
          }
        }
      }
    }
  }
  
  /// Prints check for current order
  func printCheck(check: Check) {
    let manager = OrderManager.currentOrder
    
    SwiftSpinner.show("Печать чека")
    ServerManager.sharedManager.printCheck(check) { response in
      dispatch_async(dispatch_get_main_queue()) {
        switch response.result {
        case .Success(_):
          Settings.sharedInstance.checksSum += manager.totalPrice
          Settings.sharedInstance.cashBalance += manager.payments.reduce(0, combine: { (sum, payment) -> Double in
            if payment.method == .Cash {
              return payment.amount
            }
            
            return 0
          })
          if OrderManager.currentOrder.hasDiscountItems {
            Settings.sharedInstance.discountsBalance -= OrderManager.currentOrder.totalPrice
          }
          Settings.saveToUserDefaults()
          SwiftSpinner.hide()
          OrderManager.currentOrder.clearOrder()
          ClientManager.currentClient = nil
          NSNotificationCenter.defaultCenter().postNotificationName(endCheckoutNotification, object: nil)
        case .Failure(let error):
          SwiftSpinner.show("Не удалось напечатать чек", animated: false)
          print(error)
        }
      }
    }
  }
}
