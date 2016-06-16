import Foundation

let newItemNotification = "newItemNotification"

struct Payment {
  let amount: Double
  let method: Method

  enum Method: Int {
    case Cash
    case Card
  }
  
  var dict: [String: AnyObject]? {
    return ["type": method.rawValue, "amount": amount]
  }
}

class OrderManager {
  
  static var currentOrder = OrderManager()
  
  var items = [OrderItem]()
  var payments = [Payment]()
  
  var totalPrice: Double {
    return items.reduce(0) { (sum, item) -> Double in
      return sum + item.totalPrice
    }
  }
  
  var residual: Double {
    return totalPrice - payments.reduce(0) { (sum, payment) -> Double in
      return payment.amount + sum
    }
  }
  
  func clearOrder() {
    OrderManager.currentOrder = OrderManager()
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