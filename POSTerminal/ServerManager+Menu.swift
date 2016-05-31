//
//  ServerManager+Menu.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 31/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire
import SwiftyJSON

//MARK: - Menu

extension ServerManager {
  func getMenu(completion: ((response: ServerResponse<[Product], ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<[Product], ServerError>
    return nil
  }
}