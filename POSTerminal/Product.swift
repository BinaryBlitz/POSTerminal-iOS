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
  let price = RealmOptional<Double>()
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
    guard let id = json["ref"].string, name = json["name"].string,
        parentId = json["parentRef"].string, isGroup = json["isGroup"].bool else {
      return nil
    }
    
    let product = Product()
    product.id = id
    product.name = name
    
    if isGroup {
      product.type = .Group
    } else {
      product.type = .Item
    }
    
    if parentId == "" {
      product.parentId = nil
    } else {
      product.parentId = parentId
    }
    
    if let valueAddedTax = json["valueAddedTax"].int {
      product.valueAddedTax = valueAddedTax
    }
    
    return product
  }
  
  var json: JSON? {
    return nil
  }
}