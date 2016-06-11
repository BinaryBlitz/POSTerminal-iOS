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