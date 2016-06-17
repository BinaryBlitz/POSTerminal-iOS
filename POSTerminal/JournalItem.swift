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
    fatalError("init(realm:schema:) has not been implemented")
  }
  
  required init() {
    super.init()
  }
  
  required init(value: AnyObject, schema: RLMSchema) {
    fatalError("init(value:schema:) has not been implemented")
  }
  
  override static func primaryKey() -> String? {
    return "number"
  }
}