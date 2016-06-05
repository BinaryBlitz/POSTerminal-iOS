//
//  ProductCollectionViewCell.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 04/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

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
    
    categorySetaratorView.backgroundColor = UIColor.elementsAndH1Color()
    priceLabel.textColor = UIColor.h4Color()
    categoryNameLabel.textColor = UIColor.h4Color()
    nameLabel.textColor = UIColor.elementsAndH1Color()
    
    backgroundColor = UIColor.whiteColor()
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
  
  func configureWith(product: Product) {
    guard let price = product.price.value else { return }
    
    nameLabel.text = product.name
    categoryNameLabel.text = product.category
    priceLabel.text = "\(price) р."
  }
}
