//
//  Settings.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 31/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Foundation

class Settings: NSObject, NSCoding {
  
  static let sharedInstance = Settings()
  
  var wpBase: Host?
  var equipServ: Host?
  
  override init() { super.init() }
  
  required init?(coder aDecoder: NSCoder) {
    wpBase = aDecoder.decodeObjectForKey("wpBase") as? Host
    equipServ = aDecoder.decodeObjectForKey("equipServ") as? Host
    super.init()
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(wpBase, forKey: "wpBase")
    aCoder.encodeObject(equipServ, forKey: "equipServ")
  }
}