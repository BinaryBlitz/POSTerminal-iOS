import Foundation

let newItemNotification = "newItemNotification"

class OrderManager {
  
  static var currentOrder = OrderManager()
  
  var items = [OrderItem]()
  
  var totalPrice: Double {
    return items.reduce(0) { (sum, item) -> Double in
      return sum + item.totalPrice
    }
  }
  
  func clearOrder() {
    items = []
  }
  
  func append(product: Product) {
    defer {
      NSNotificationCenter.defaultCenter().postNotificationName(newItemNotification, object: nil, userInfo: ["product": product])
    }
    
    for item in items {
      if item.product.id == product.id {
        item.inrementQuantity()
        return
      }
    }
    
    items.append(OrderItem(product: product))
  }
}