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
    guard let id = json["clientRef"].string, name = json["clientName"].string,
        balance = json["balance"].double, code = json["clientCode"].string else {
      return nil
    }
    
    return Client(id: id, code: code, name: name, balance: balance)
  }
  
  var dict: [String: AnyObject]? {
    return nil
  }
}