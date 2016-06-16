import UIKit

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
}

extension CheckoutViewController: PaymentControllerDelegate {
  
  func didUpdatePayments() {
    priceLabel.text = "\(OrderManager.currentOrder.residual.format()) р."
    let residual = OrderManager.currentOrder.residual
    if residual == 0 {
      //TODO: create check
      OrderManager.currentOrder.clearOrder()
      ClientManager.currentClient = nil
      NSNotificationCenter.defaultCenter().postNotificationName(endCheckoutNotification, object: nil)
    } else if residual < 0 {
      presentAlertWithTitle("Сдача", andMessage: "\(-residual) рублей")
    }
  }
  
}
