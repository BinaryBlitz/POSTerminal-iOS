//
//  Settings.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 31/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Foundation

class Settings: NSObject, NSCoding {
  
  static private(set) var sharedInstance = Settings()
  
  var wpBase: Host?
  var equipServ: Host?
  
  var cashBalance: Double = 0
  
  override init() { super.init() }
  
  required init?(coder aDecoder: NSCoder) {
    wpBase = aDecoder.decodeObjectForKey("wpBase") as? Host
    equipServ = aDecoder.decodeObjectForKey("equipServ") as? Host
    cashBalance = aDecoder.decodeDoubleForKey("cashBalance") 
    super.init()
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(wpBase, forKey: "wpBase")
    aCoder.encodeObject(equipServ, forKey: "equipServ")
    aCoder.encodeDouble(cashBalance, forKey: "cashBalance")
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