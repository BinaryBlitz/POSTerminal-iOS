//
//  WPBaseRouter.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 01/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire

enum WPBaseRouter {
  case Menu
  case Create(check: Check)
}

extension WPBaseRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.wpBase?.baseURL ?? ""
    
    switch self {
    case .Menu:
      return "\(baseURL)/hs/Dishes/InfoDishes"
    case .Create(_):
      return "\(baseURL)/checks"
    }
  }
  
  var login: String? {
    return Settings.sharedInstance.wpBase?.login
  }
  
  var password: String? {
    return Settings.sharedInstance.wpBase?.password
  }
  
  var method: Alamofire.Method {
    switch self {
    case .Menu:
      return .GET
    case .Create(_):
      return .POST
    }
  }
  
  //TODO: Add parameters
  var parameters: [String: AnyObject]? {
    return nil
  }
}
