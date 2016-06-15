//
//  KeyboardButton.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 15/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit
import PureLayout

class KeyboardButton: UIButton {
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    titleLabel?.font = UIFont.boldSystemFontOfSize(28)
    setTitleColor(UIColor.h4Color(), forState: .Normal)
    
    layer.borderColor = UIColor.elementsAndH1Color().CGColor
    layer.borderWidth = 1.5
    
    backgroundColor = UIColor.whiteColor()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let shadowPath = UIBezierPath(rect: bounds)
    layer.masksToBounds = false
    layer.shadowColor = UIColor.shadowColor().CGColor
    layer.shadowOffset = CGSize(width: 0, height: 5)
    layer.shadowOpacity = 0.5
    layer.shadowRadius = 20
    layer.shadowPath = shadowPath.CGPath
    
    layer.cornerRadius = layer.bounds.width / 2
  }
}
