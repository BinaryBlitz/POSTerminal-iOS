import UIKit
import RealmSwift

class ProductCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var categoryNameLabel: UILabel!
  @IBOutlet weak var categorySetaratorView: UIView!
  @IBOutlet weak var categoryBackgroundView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    
    layer.cornerRadius = 5
    categoryBackgroundView.layer.cornerRadius = 5
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

extension ProductCollectionViewCell: ProductConfigurable {
  func configureWith(product: Product) {
    
    categorySetaratorView.backgroundColor = UIColor.lightOrangeColor()
    priceLabel.textColor = UIColor.h4Color()
    categoryNameLabel.textColor = UIColor.h4Color()
    nameLabel.textColor = UIColor.lightOrangeColor()
    
    backgroundColor = UIColor.whiteColor()
    
    nameLabel.text = product.name.uppercaseString
    categoryNameLabel.text = product.category.uppercaseString
    
    if let price = product.price.value {
      priceLabel.text = "\(price.format()) р."
    }
  }
}
