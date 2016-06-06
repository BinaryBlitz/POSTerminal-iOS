//
//  CheckItemTableViewCell.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 06/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CheckItemTableViewCell: UITableViewCell {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var quantityView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
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
    categoryLabel.textColor = UIColor.h5Color()
    categoryLabel.text = item.product.category
    
    if let price = item.product.price.value {
      priceLabel.text = "\(Int(price)) р."
    } else {
      priceLabel.text = "0 р."
    }
    priceLabel.textColor = UIColor.h4Color()
  }
}
