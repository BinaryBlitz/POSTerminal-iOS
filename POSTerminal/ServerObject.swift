//
//  ServerObject.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import SwiftyJSON

protocol ServerObject {
  associatedtype Type
  static func createWith(json: JSON) -> Type?
  var json: JSON? { get }
}

extension ServerObject {
  static func createWith(json: JSON) -> Type? {
    return nil
  }
  var json: JSON? { return nil }
}
