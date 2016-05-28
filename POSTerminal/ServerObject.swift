//
//  ServerObject.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import SwiftyJSON

protocol ServerObject {
  func createWith(json: JSON) -> JSON?
}

extension ServerObject {
  func createWith(json: JSON) -> JSON? {
    return nil
  }
}
