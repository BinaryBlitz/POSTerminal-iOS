import Foundation

class Settings: NSObject, NSCoding {
  
  static private(set) var sharedInstance = Settings()
  
  var baseColorHex: String? = nil
  
  var wpBase: Host?
  var equipServ: Host?
  var currentCheckNumber: Int = 0
  
  var cashBalance: Double = 0
  
  var checksSum: Double = 0
  var ordersSum: Double = 0
  
  var discountCategoryName: String? = nil
  var discountsBalance: Double = 0
  
  var isCashless: Bool = true
  
  override init() { super.init() }
  
  required init?(coder aDecoder: NSCoder) {
    baseColorHex = aDecoder.decodeObjectForKey("baseColorHex") as? String
    wpBase = aDecoder.decodeObjectForKey("wpBase") as? Host
    equipServ = aDecoder.decodeObjectForKey("equipServ") as? Host
    cashBalance = aDecoder.decodeDoubleForKey("cashBalance")
    checksSum = aDecoder.decodeDoubleForKey("checksSum")
    ordersSum = aDecoder.decodeDoubleForKey("ordersSum")
    currentCheckNumber = Int(aDecoder.decodeIntForKey("currentCheckNumber"))
    discountCategoryName = aDecoder.decodeObjectForKey("discountCategoryName") as? String
    discountsBalance = aDecoder.decodeDoubleForKey("discountsBalance")
    isCashless = aDecoder.decodeBoolForKey("isCashless")
    super.init()
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(baseColorHex, forKey: "baseColorHex")
    aCoder.encodeObject(wpBase, forKey: "wpBase")
    aCoder.encodeObject(equipServ, forKey: "equipServ")
    aCoder.encodeDouble(cashBalance, forKey: "cashBalance")
    aCoder.encodeDouble(checksSum, forKey: "checksSum")
    aCoder.encodeDouble(ordersSum, forKey: "ordersSum")
    aCoder.encodeInt(Int32(currentCheckNumber), forKey: "currentCheckNumber")
    aCoder.encodeObject(discountCategoryName, forKey: "discountCategoryName")
    aCoder.encodeDouble(discountsBalance, forKey: "discountsBalance")
    aCoder.encodeBool(isCashless, forKey: "isCashless")
  }
  
  static func loadFormUserDefaults() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    if let encodedObject = userDefaults.objectForKey("settings") as? NSData {
      let settings = NSKeyedUnarchiver.unarchiveObjectWithData(encodedObject) as! Settings
      sharedInstance = settings
    }
  }
  
  static func saveToUserDefaults() {
    let encodedObject = NSKeyedArchiver.archivedDataWithRootObject(sharedInstance)
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.setObject(encodedObject, forKey: "settings")
    userDefaults.synchronize()
  }
}