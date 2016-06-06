//
//  OrderItem.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 06/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Foundation

class OrderItem {
  let product: Product
  private(set) var quantity: Int
  
  init(product: Product, quantity: Int = 1) {
    self.product = product
    self.quantity = quantity
  }
  
  var totalPrice: Double {
    guard let price = product.price.value else { return 0 }
    return price * Double(quantity)
  }
  
  func inrementQuantity() {
    quantity += 1
  }
}