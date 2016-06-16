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
  }
  
  //MARK: - Actions
  
  @IBAction func payButtonAction() {
    let amountToPay = OrderManager.currentOrder.totalPrice
    OrderManager.currentOrder.payments.append(Payment(amount: amountToPay, method: .Card))
    delegate?.didUpdatePayments()
  }
  
}
