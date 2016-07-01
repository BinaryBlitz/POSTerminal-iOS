import UIKit
import Darwin

class CategoryCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var backgroundContentView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundContentView.layer.borderWidth = 1
    backgroundContentView.layer.cornerRadius = 4
    
    layer.cornerRadius = 5
    
    nameLabel.lineBreakMode = .ByWordWrapping
    nameLabel.numberOfLines = 3
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let shadowPath = UIBezierPath(rect: bounds)
    layer.masksToBounds = false
    layer.shadowColor = UIColor.shadowColor().CGColor
    layer.shadowOffset = CGSize(width: 0, height: 10)
    layer.shadowOpacity = 0.65
    layer.shadowRadius = 55
    layer.shadowPath = shadowPath.CGPath
  }
}

extension CategoryCollectionViewCell: ProductConfigurable {
  func configureWith(product: Product) {
    nameLabel.textColor = UIColor.lightOrangeColor()
    backgroundColor = UIColor.whiteColor()
    backgroundContentView.layer.borderColor = UIColor.lightOrangeColor().CGColor
    
    nameLabel.text = product.name.uppercaseString
  }
}
