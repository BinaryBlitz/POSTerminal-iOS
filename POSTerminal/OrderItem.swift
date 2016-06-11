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