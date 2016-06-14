import UIKit

class CashPaymentViewController: UIViewController {
  
  @IBOutlet weak var firstCashButton: UIButton!
  @IBOutlet weak var secondCashButton: UIButton!
  @IBOutlet weak var thirdCashButton: UIButton!
  @IBOutlet weak var fourthCashButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    [firstCashButton, secondCashButton, thirdCashButton, fourthCashButton].forEach { button in
      button.hidden = true
    }
    
    view.backgroundColor = UIColor.clearColor()
    
    setUpButtons()
  }
  
  func setUpButtons() {
    let orderTotal = OrderManager.currentOrder.totalPrice
    let labels = generateBillsPredictionFor(Int(orderTotal))
    
    let buttons = [firstCashButton, secondCashButton, thirdCashButton, fourthCashButton]
    for (i, button) in buttons.enumerate() {
      if labels.count > i {
        button.setTitle(format(labels[i]), forState: .Normal)
        button.hidden = false
      }
    }
  }
  
  func format(number: Int) -> String {
    return "\(number) р"
  }
  
  func generateBillsPredictionFor(orderTotal: Int) -> [Int] {
    let bills = [50, 100, 500, 1000, 5000]
    
    var result: [Int] = []
    for bill in bills {
      if orderTotal % bill != 0 {
        result.append(((orderTotal / bill) + 1) * bill)
      } else {
        result.append((orderTotal / bill) * bill)
      }
    }
    
    return Array(Set(result)).sort()
  }

}
