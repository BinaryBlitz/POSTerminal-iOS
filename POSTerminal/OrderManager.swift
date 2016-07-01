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
  
  var hasDiscountItems: Bool {
    let discountItems = items.flatMap { (item) -> OrderItem? in
      if item.product.category.lowercaseString == Settings.sharedInstance.discountCategoryName?.lowercaseString {
        return item
      }
      return nil
    }
    return discountItems.count != 0
  }
  
  var totalPrice: Double {
    return items.reduce(0) { (sum, item) -> Double in
      return sum + item.totalPrice
    }
  }
  
  enum PaymentType {
    case Cash
    case Balance
    case Mixed
  }
  
  var paymentType: PaymentType {
    let cashCount = payments.reduce(0) { (sum, payment) -> Int in
      if payment.method == .Cash {
        return 1
      }
      
      return 0
    }
    let balanceCount = payments.reduce(0) { (sum, payment) -> Int in
      if payment.method == .Card {
        return 1
      }
      
      return 0
    }
    
    if cashCount == payments.count {
      return .Cash
    } else if balanceCount == payments.count {
      return .Balance
    } else {
      return .Mixed
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
      if item.product.productId == product.productId {
        item.inrementQuantity()
        return
      }
    }
    
    items.append(OrderItem(product: product))
  }
  
}