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
  
  let manager: Manager
  
  init() {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.protocolClasses!.insert(RedSocketURLProtocol.self, atIndex: 0)
    self.manager = Alamofire.Manager(configuration: configuration)
  }
  
  func createRequest(router: ServerRouter) throws -> Request {
      guard let login = router.login, password = router.password else {
        throw ServerError.Unauthorized
      }
    
      return manager.request(router.method, router.path, parameters: router.parameters)
                    .authenticate(user: login, password: password)
  }
}
