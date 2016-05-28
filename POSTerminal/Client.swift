//
//  Client.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Realm
import RealmSwift
import SwiftyJSON

class Client: Object, ServerObject {
  dynamic var id: String = ""
  dynamic var name: String = ""
  dynamic var balance: Int = 0
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension Client {
  func createWith(json: JSON) -> JSON? {
    return nil
  }
}