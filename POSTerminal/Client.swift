import Realm
import RealmSwift
import SwiftyJSON

struct Client {
  let id: String
  let code: String
  let name: String
  var balance: Int = 0
}

extension Client: ServerObject {
  
  static func createWith(json: JSON) -> Client? {
    guard let id = json["clientRef"].string, name = json["clientName"].string,
        balance = json["balance"].int, code = json["clientCode"].string else {
      return nil
    }
    
    return Client(id: id, code: code, name: name, balance: balance)
  }
  
  var json: JSON? {
    return nil
  }
}