import UIKit

class CardPaymentViewController: UIViewController {
  
  @IBOutlet weak var payButton: UIButton!
  
  weak var delegate: PaymentControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.clearColor()
    
    payButton.layer.cornerRadius = 10
    payButton.backgroundColor = UIColor.elementsAndH1Color()
    payButton.tintColor = UIColor.whiteColor()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateColors), name: UpdateColorsNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func updateColors() {
    payButton.backgroundColor = UIColor.elementsAndH1Color()
  }
  
  //MARK: - Actions
  
  @IBAction func payButtonAction() {
    let amountToPay = OrderManager.currentOrder.totalPrice
    OrderManager.currentOrder.payments.append(Payment(amount: amountToPay, method: .Card))
    delegate?.didUpdatePayments()
  }
  
}
