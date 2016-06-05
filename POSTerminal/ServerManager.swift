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
  
  var activityIndicatorVisible: Bool {
    get {
      return UIApplication.sharedApplication().networkActivityIndicatorVisible
    }
    set {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = newValue
    }
  }
  
  func createRequest(router: ServerRouter) throws -> Request {
    guard let login = router.login, password = router.password else {
      throw ServerError.Unauthorized
    }
    
    let credentialData = "\(login):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
    let base64Credentials = credentialData.base64EncodedStringWithOptions([])
    
    let headers = ["Authorization": "Basic \(base64Credentials)"]
    
    return manager.request(router.method, router.path, parameters: router.parameters, headers: headers)
  }
}
