import UIKit

class CheckItemTableViewCell: UITableViewCell {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var quantityView: UIView!
  
  @IBOutlet weak var actionsStackView: UIStackView!
  @IBOutlet weak var minusActionView: UIView!
  @IBOutlet weak var plusActionView: UIView!
  
  enum CheckItemState {
    case Normal
    case Editing
  }
  
  var state: CheckItemState = .Normal {
    didSet {
      updateState(state)
    }
  }
  
  weak var delegate: CheckItemCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeState))
    contentView.addGestureRecognizer(tapGesture)
  }
  
  func configureWith(item: OrderItem) {
    quantityLabel.text = String(item.quantity)
    quantityView.layer.cornerRadius = 17.5
    if item.quantity < 2 {
      quantityView.backgroundColor = UIColor.whiteColor()
      quantityLabel.textColor = UIColor.h5Color()
    } else {
      quantityView.backgroundColor = UIColor.elementsAndH1Color()
      quantityLabel.textColor = UIColor.whiteColor()
    }
    
    nameLabel.textColor = UIColor.h4Color()
    nameLabel.text = item.product.name
    
    if let price = item.product.price.value {
      priceLabel.text = "\(price.format()) р."
    } else {
      priceLabel.text = "0 р."
    }
    priceLabel.textColor = UIColor.h4Color()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let shadowPath = UIBezierPath(rect: quantityView.bounds)
    quantityView.layer.masksToBounds = false
    quantityView.layer.shadowColor = UIColor.grayColor().CGColor
    quantityView.layer.shadowOffset = CGSize(width: 0, height: 10)
    quantityView.layer.shadowOpacity = 0.65
    quantityView.layer.shadowRadius = 55
    quantityView.layer.shadowPath = shadowPath.CGPath
  }
  
  func changeState() {
    if state == .Normal {
      state = .Editing
    } else {
      state = .Normal
    }
    delegate?.didUpdateStateFor(self)
  }
  
  private func updateState(state: CheckItemState) {
    switch state {
    case .Normal:
      actionsStackView.hidden = true
    case .Editing:
      actionsStackView.hidden = false
    }
  }
  
  //MARK: - Action
  
  @IBAction func plusButtonAction() {
    delegate?.didTouchPlusButtonIn(self)
  }
  
  @IBAction func minusButtonAction() {
    delegate?.didTouchMinusButtonIn(self)
  }
}
