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

class Client: Object {
  dynamic var id: String = ""
  dynamic var name: String = ""
  dynamic var balance: Int = 0
  
  static var currentClient: Client?
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension Client: ServerObject {
  
  static func createWith(json: JSON) -> Client? {
    guard let id = json["clientRef"].string, name = json["clientName"].string,
        balance = json["balance"].int else {
      return nil
    }
    
    return {
      $0.id = id
      $0.name = name
      $0.balance = balance
      return $0
    }(Client())
  }
  
  var json: JSON? {
    return nil
  }
}