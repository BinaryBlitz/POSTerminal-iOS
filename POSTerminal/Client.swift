import Realm
import RealmSwift
import SwiftyJSON

struct Client {
  let id: String
  let code: String
  let name: String
  var balance: Double = 0
  var identity: ClientIdentity? = nil
  
  init(id: String, code: String, name: String, balance: Double) {
    self.id = id
    self.code = code
    self.name = name
    self.balance = balance
  }
}

extension Client: ServerObject {
  
  static func createWith(json: JSON) -> Client? {
    guard let id = json["clientRef"].string, name = json["clientName"].string, code = json["clientCode"].string else {
      return nil
    }
    
    let balance: Double
    
    if let doubleBalance = json["balance"].double {
      balance = doubleBalance
    } else if let stringBalance = json["balance"].string, doubleBalance = Double(stringBalance) {
      balance = doubleBalance
    } else {
      return nil
    }
    
    return Client(id: id, code: code, name: name, balance: balance)
  }
  
  var dict: [String: AnyObject]? {
    return nil
  }
}