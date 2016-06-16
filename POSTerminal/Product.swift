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
  dynamic var parentId: String = ""
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
  
  var category: String? {
    guard let realm = try? Realm() where parentId != "" else { return nil }
    let parent = realm.objectForPrimaryKey(Product.self, key: parentId)
    return parent?.name
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
    product.parentId = parentId
    
    if isGroup {
      product.type = .Group
    } else {
      product.type = .Item
    }
    
    if let price = json["price"].double where product.type == .Item {
      product.price.value = price
    }
    
    if let valueAddedTax = json["valueAddedTax"].int {
      product.valueAddedTax = valueAddedTax
    }
    
    return product
  }
  
  var dict: [String: AnyObject]? {
    return nil
  }
}