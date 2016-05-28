//
//  ServerObject.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import SwiftyJSON

protocol ServerObject {
  static func createWith(json: JSON) -> JSON?
  var json: JSON? { get }
}

extension ServerObject {
  static func createWith(json: JSON) -> JSON? {
    return nil
  }
  var json: JSON? { return nil }
}
