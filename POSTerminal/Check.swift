//
//  Check.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 28/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import SwiftyJSON

struct Check {
  let number: Int
  let isFiscal: Bool
  let clientId: String
  var items = []
}

extension Check: ServerObject {
  var json: JSON? {
    //TODO: return real JSON
    return nil
  }
}