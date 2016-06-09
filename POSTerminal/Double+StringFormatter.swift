//
//  Double+StringFormatter.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 09/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Foundation

extension Double {
  func format() -> String {
    let fraction = self - Double(Int(self))
    if fraction == 0 {
      return "\(Int(self))"
    }
    
    return NSString(format: "%.2f", self) as String
  }
}