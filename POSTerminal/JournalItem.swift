import Realm
import RealmSwift

class JournalItem: Object {
  dynamic var number: Int = 0
  dynamic var clientCode: String = ""
  dynamic var createdAt: NSDate = NSDate()
  dynamic var amount: Double = 0
  
  init(check: Check) {
    number = check.number
    clientCode = check.clientCode
    createdAt = NSDate()
    amount = check.items.reduce(0, combine: { (sum, item) -> Double in
      return sum + item.totalPrice
    })
    super.init()
  }
  
  required init(realm: RLMRealm, schema: RLMObjectSchema) {
    super.init(realm: realm, schema: schema)
  }
  
  required init() {
    super.init()
  }
  
  required init(value: AnyObject, schema: RLMSchema) {
    super.init(value: value, schema: schema)
  }
  
  override static func primaryKey() -> String? {
    return "number"
  }
}