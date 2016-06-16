import SwiftyJSON
import Foundation

struct Check {
  let number: Int
  let isFiscal: Bool
  let clientId: String
  let terminalId: String
  let createdAt: NSDate
  var items: [OrderItem] = []
  var payments: [Payment] = []
  var text: [String] = []
  
  init(clientId: String, items: [OrderItem], payemnts: [Payment]) {
    let number = Settings.sharedInstance.currentCheckNumber + 1
    Settings.sharedInstance.currentCheckNumber += 1
    Settings.saveToUserDefaults()
    self.number = number
    self.isFiscal = true
    self.clientId = clientId
    self.items = items
    self.payments = payemnts
    terminalId = uuid!
    createdAt = NSDate()
  }
  
  private func convertDateToData(date: NSDate) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmss"
    return formatter.stringFromDate(NSDate())
  }
  
}

extension Check: ServerObject {
  
  static func createWith(json: JSON) -> Check? {
    return nil
  }
  
  var dict: [String: AnyObject]? {
    let object: [String: AnyObject] = [
      "number": number,
      "Data": convertDateToData(createdAt),
      "isFiscal": isFiscal,
      "clientRef": clientId,
      "terminalID": terminalId,
      "items": items.flatMap { (product) -> [String: AnyObject]? in
        return product.dict
      },
      "payments": payments.flatMap { (payment) -> [String: AnyObject]? in
        return payment.dict
      }
    ]
    
    return object
  }
  
}