import Alamofire

enum WPBaseRouter {
  case Menu
  case Create(check: Check)
  case GetInfo(identity: ClientIdentity)
}

extension WPBaseRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.wpBase?.baseURL ?? ""
    
    switch self {
    case .Menu:
      return "\(baseURL)/hs/Dishes/InfoDishes"
    case .Create(_):
      return "\(baseURL)/checks"
    case .GetInfo(_):
      return "\(baseURL)/hs/Client/InfoClient"
    }
  }
  
  var login: String? {
    return Settings.sharedInstance.wpBase?.login
  }
  
  var password: String? {
    return Settings.sharedInstance.wpBase?.password
  }
  
  var method: Alamofire.Method {
    switch self {
    case .Menu:
      return .GET
    case .Create(_):
      return .POST
    case .GetInfo(_):
      return .POST
    }
  }
  
  var encoding: Alamofire.ParameterEncoding {
    switch self {
    case .Create(_), .GetInfo(_):
      return .JSON
    default:
      return .URL
    }
  }
  
  var parameters: [String: AnyObject]? {
    switch self {
    case .Menu:
      return nil
    case let .Create(check):
      return check.json?.dictionaryObject
    case let .GetInfo(identity):
      return ["type": identity.type.rawValue, "code": identity.code]
    }
  }
}
