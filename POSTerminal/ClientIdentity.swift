//
//  ClientIdentity.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

struct ClientIdentity {
  
  let code: String
  let type: Type

  enum Type: String {
    case TacksData
    case ScanData
    case RFIDData
  }
}
