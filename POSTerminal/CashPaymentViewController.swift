import UIKit

class CashPaymentViewController: UIViewController {
  
  @IBOutlet weak var firstCashButton: UIButton!
  @IBOutlet weak var secondCashButton: UIButton!
  @IBOutlet weak var thirdCashButton: UIButton!
  @IBOutlet weak var fourthCashButton: UIButton!
  
  let bills = [50, 100, 500, 1000, 5000]

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.clearColor()
    
    setUpButtons()
  }
  
  func setUpButtons() {
  }
  
}
