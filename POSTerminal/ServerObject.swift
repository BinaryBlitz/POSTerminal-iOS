//
//  ServerObject.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import SwiftyJSON

protocol ServerObject {
  associatedtype ObjectType = Self
  static func createWith(json: JSON) -> ObjectType?
  var json: JSON? { get }
}
