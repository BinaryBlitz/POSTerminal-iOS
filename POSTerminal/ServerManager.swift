//
//  ServerManager.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire

class ServerManager {
  
  static let sharedManager = ServerManager()
  
  let manager = Manager.sharedInstance
  let baseURL: String!
  
  var login: String?
  var password: String?
  
  init() {
    self.baseURL = NSBundle.mainBundle().objectForInfoDictionaryKey("BaseURL") as! String
  }
}
