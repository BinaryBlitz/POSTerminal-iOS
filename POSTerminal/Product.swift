//
//  Product.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Realm
import RealmSwift
import SwiftyJSON

enum ProductType: String {
  case Group
  case Item
}

class Product: Object {
  dynamic var id: String = ""
  dynamic var name: String = ""
  dynamic var price: Double = -1 // -1 for no price
  dynamic var parentId: String?
  dynamic var typeValue: String = ProductType.Group.rawValue
  dynamic var valueAddedTax: Int = 0
  
  var type: ProductType {
    get {
      return ProductType(rawValue: typeValue)!
    }
    set {
      self.typeValue = newValue.rawValue
    }
  }
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension Product: ServerObject {
  static func createWith(json: JSON) -> Product? {
    return nil
  }
  
  var json: JSON? {
    return JSON([])
  }
}