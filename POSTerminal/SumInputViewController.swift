import UIKit

class SumInputViewController: UIViewController {
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var sumLabelContainer: CardView!
  @IBOutlet weak var sumLabel: UILabel!
  
  @IBOutlet weak var clearButton: KeyboardButton!
  @IBOutlet weak var payButton: KeyboardButton!
  
  private let zeroString = "0"

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    contentView.layer.cornerRadius = 10
    titleLabel.textColor = UIColor.h5Color()
    
    sumLabel.text = zeroString
    sumLabel.backgroundColor = UIColor.whiteColor()
    
    sumLabelContainer.backgroundColor = UIColor.whiteColor()
    
    clearButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
    clearButton.setTitleColor(UIColor.h3Color(), forState: .Normal)
    clearButton.layer.borderWidth = 0
    
    payButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
    payButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    payButton.backgroundColor = UIColor.elementsAndH1Color()
    payButton.layer.borderWidth = 0
    
    payButton.backgroundColor = UIColor.h5Color()
    payButton.enabled = false
  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func numberButtonAction(sender: UIButton) {
    guard let title = sender.titleLabel?.text, _ = Int(title) else { return }
    if sumLabel.text == zeroString {
      sumLabel.text = title
    } else if let oldText = sumLabel.text {
      let newText = "\(oldText)\(title)"
      sumLabel.text = newText
    }
    updatePayButton()
  }
  
  @IBAction func clearButtonAction() {
    sumLabel.text = zeroString
    updatePayButton()
  }
  
  func updatePayButton() {
    if let text = sumLabel.text, sum = Double(text) where sum >= OrderManager.currentOrder.totalPrice {
      payButton.enabled = true
      payButton.backgroundColor = UIColor.elementsAndH1Color()
    }
  }
  
  @IBAction func payButtonAction() {
    OrderManager.currentOrder.clearOrder()
    ClientManager.currentClient = nil
    NSNotificationCenter.defaultCenter().postNotificationName(endCheckoutNotification, object: nil)
    dismissViewControllerAnimated(true, completion: nil)
  }
  
}
