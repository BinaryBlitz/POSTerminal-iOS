import Realm
import RealmSwift
import SwiftyJSON

class Client: Object {
  dynamic var id: String = ""
  dynamic var code: String = ""
  dynamic var name: String = ""
  dynamic var balance: Int = 0
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension Client: ServerObject {
  
  static func createWith(json: JSON) -> Client? {
    guard let id = json["clientRef"].string, name = json["clientName"].string,
        balance = json["balance"].int, code = json["clientCode"].string else {
      return nil
    }
    
    return {
      $0.id = id
      $0.code = code
      $0.name = name
      $0.balance = balance
      return $0
    }(Client())
  }
  
  var json: JSON? {
    return nil
  }
}