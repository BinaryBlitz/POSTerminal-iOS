//
//  CashButton.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 14/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CashButton: UIButton {
 
  override func awakeFromNib() {
    super.awakeFromNib()
    
    layer.cornerRadius = 5
    layer.borderColor = UIColor.elementsAndH1Color().CGColor
    layer.borderWidth = 1
    backgroundColor = UIColor.whiteColor()
    
    setTitleColor(UIColor.elementsAndH1Color(), forState: .Normal)
    titleLabel?.font = UIFont.boldSystemFontOfSize(22)
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