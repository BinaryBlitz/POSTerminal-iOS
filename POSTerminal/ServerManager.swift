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
  let baseURL: String!
  
  var login: String?
  var password: String?
  
  init() {
    self.baseURL = NSBundle.mainBundle().objectForInfoDictionaryKey("BaseURL") as! String
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.protocolClasses!.insert(RedSocketURLProtocol.self, atIndex: 0)
    self.manager = Alamofire.Manager(configuration: configuration)
  }
  
  //MARK: - Basic methods
  
  private func request(method: Alamofire.Method, path: String,
    parameters: [String : AnyObject]?,
    encoding: ParameterEncoding) throws -> Request {
      guard let login = login, password = password else {
        throw ServerError.Unauthorized
      }
    
      return manager.request(method, path, parameters: parameters, encoding: encoding)
                    .authenticate(user: login, password: password)
  }
  
  
  /// GET request with api token
  func get(path: String, params: [String: AnyObject]? = nil) throws -> Request {
    return try request(.GET, path: path, parameters: params, encoding: .URL)
  }
  
  /// POST request with api token
  func post(path: String, params: [String: AnyObject]? = nil) throws -> Request {
    return try request(.POST, path: path, parameters: params, encoding: .JSON)
  }
}
