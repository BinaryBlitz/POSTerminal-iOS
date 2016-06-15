import UIKit

class CardView: UIView {
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    layer.cornerRadius = 5
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let shadowPath = UIBezierPath(rect: bounds)
    layer.masksToBounds = false
    layer.shadowColor = UIColor.shadowColor().CGColor
    layer.shadowOffset = CGSize(width: 0, height: 5)
    layer.shadowOpacity = 0.65
    layer.shadowRadius = 27
    layer.shadowPath = shadowPath.CGPath
  }
}

