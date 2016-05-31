//
//  ServerError.swift
//  Athlete
//
//  Created by Dan Shevlyuk on 20/02/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import Foundation

enum ServerError: ErrorType {
  case Unauthorized
  case InternalServerError
  case UnspecifiedError
  case InvalidData
  case NotConnectedToInternet
  case NetworkConnectionLost
  case Cancelled
  
  init(error: NSError) {
    guard let error = error as? NSURLError else {
      self = .UnspecifiedError
      return
    }
    
    switch error {
    case .NotConnectedToInternet:
      self = .NotConnectedToInternet
    case .NetworkConnectionLost:
      self = .NetworkConnectionLost
    case .Cancelled:
      self = .Cancelled
    default:
      self = .UnspecifiedError
    }
  }
}