import UIKit
import RealmSwift

class CheckoutViewController: UIViewController {
  
  enum Notifications {
    static let PaymentFinished = "PaymentFinished"
  }
  
  @IBOutlet weak var priceTitleLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var paymentTypeSwitch: UISegmentedControl!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.whiteColor()
    priceTitleLabel.textColor = UIColor.h5Color()
    priceTitleLabel.font = UIFont.boldSystemFontOfSize(18)
    priceLabel.textColor = UIColor.h4Color()
    priceLabel.font = UIFont.boldSystemFontOfSize(20)
    priceLabel.text = "\(OrderManager.currentOrder.residual.format()) р."
    
    paymentTypeSwitch.tintColor = UIColor.elementsAndH1Color()
    let font = UIFont.boldSystemFontOfSize(17)
    let textAttributes = [NSFontAttributeName: font]
    paymentTypeSwitch.setTitleTextAttributes(textAttributes, forState: .Normal)
    
    paymentTypeSwitch.addTarget(self, action: #selector(changePaymentMethod(_:)), forControlEvents: .ValueChanged)
    
    if let _ = ClientManager.currentClient {
      paymentTypeSwitch.selectedSegmentIndex = 0
    } else {
      paymentTypeSwitch.selectedSegmentIndex = 1
      changePaymentMethod(paymentTypeSwitch)
    }
  }
  
  //MARK: - Actions
  
  func changePaymentMethod(segmentedControl: UISegmentedControl) {
    segmentedControl.userInteractionEnabled = false
    
    var currentController: UIViewController?
    var viewControllerToPresent: UIViewController?
    
    switch segmentedControl.selectedSegmentIndex {
    case 0:
      let cardPaymentController = storyboard?.instantiateViewControllerWithIdentifier("CardPayment") as! CardPaymentViewController
      cardPaymentController.delegate = self
      viewControllerToPresent = cardPaymentController
      for child in childViewControllers {
        if let content = child as? CashPaymentViewController {
          currentController = content
          break
        }
      }
    case 1:
      let cashPayementController = storyboard?.instantiateViewControllerWithIdentifier("CashPayment") as! CashPaymentViewController
      cashPayementController.delegate = self
      viewControllerToPresent = cashPayementController
      for child in childViewControllers {
        if let content = child as? CardPaymentViewController {
          currentController = content
          break
        }
      }
    default:
      return
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
          segmentedControl.userInteractionEnabled = true
        }
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "cardPayment" {
      let destination = segue.destinationViewController as! CardPaymentViewController
      destination.delegate = self
    }
  }
}

extension CheckoutViewController: PaymentControllerDelegate {
  
  func didUpdatePayments() {
    let residual = OrderManager.currentOrder.residual
    if residual == 0 {
      finishOrder()
    } else if residual < 0 {
      let alert = UIAlertController(title: "Сдача: \((-residual).format()) рублей", message: nil, preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: "Завершить заказ", style: .Default, handler: { (action) in
        if let lastPayment = OrderManager.currentOrder.payments.last {
          OrderManager.currentOrder.payments.removeLast()
          OrderManager.currentOrder.payments.append(Payment(amount: lastPayment.amount + residual, method: .Cash))
        }
        
        self.finishOrder()
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
  
  func finishOrder() {
    let manager = OrderManager.currentOrder
    guard let client = ClientManager.currentClient else  { return }
    let check = Check(client: client, items: manager.items, payemnts: manager.payments)
    ServerManager.sharedManager.create(check) { (response) in
      switch response.result {
      case .Success(_):
        Settings.sharedInstance.ordersSum += manager.totalPrice
        Settings.saveToUserDefaults()
        do {
          let realm = try Realm()
          let journalItem = JournalItem(check: check)
          try realm.write {
            realm.add(journalItem)
          }
        } catch let error {
          print(error)
        }
      case .Failure(let error):
        if !OrderManager.currentOrder.payments.isEmpty {
          OrderManager.currentOrder.payments.removeLast()
        }
        self.didUpdatePayments()
        print(error)
      }
    }
    
    ServerManager.sharedManager.printCheck(check) { response in
      switch response.result {
      case .Success(_):
        Settings.sharedInstance.checksSum += manager.totalPrice
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
      case .Failure(let error):
        print(error)
      }
    }
  }
  
}
