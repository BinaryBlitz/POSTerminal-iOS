//
//  ServerResponse.swift
//  Athlete
//
//  Created by Dan Shevlyuk on 13/03/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Alamofire

struct ServerResponse<Value, Error: ErrorType> {
  
  var value: Value? = nil
  var error: Error? = nil
  
  init() {
  }
  
  init(error: Error) {
    self.error = error
  }
  
  init(value: Value) {
    self.value = value
  }
  
  var result: Result<Value, Error> {
    if let value = value {
      return Result.Success(value)
    } else if let error = error {
      return Result.Failure(error)
    } else {
      return Result.Failure(ServerError.UnspecifiedError as! Error)
    }
  }
}