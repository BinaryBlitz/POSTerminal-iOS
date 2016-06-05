//
//  ServerManager+ClientInfo.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 06/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func getInfoFor(identity: ClientIdentity, completion: ((response: ServerResponse<Client, ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<Client, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.GetInfo(identity: identity)).validate().responseJSON { response in
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(let resultValue):
          let json = JSON(resultValue)
          if let client = Client.createWith(json) {
            completion?(response: Response(value: client))
          } else {
            completion?(response: Response(error: .InvalidData))
          }
        case .Failure(let error):
          let serverError = ServerError(error: error)
          completion?(response: Response(error: serverError))
        }
      }
      
      return request
    } catch {
      completion?(response: Response(error: .Unauthorized))
    }
    
    return nil
  }
}