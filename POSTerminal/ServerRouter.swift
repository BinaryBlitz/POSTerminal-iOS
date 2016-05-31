//
//  ServerRouter.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 01/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire

protocol ServerRouter {
  var path: String { get }
  var method: Alamofire.Method { get }
  var parameters: [String: AnyObject]? { get }
  var login: String? { get }
  var password: String? { get }
}
