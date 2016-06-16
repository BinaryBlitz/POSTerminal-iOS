import Alamofire

enum WPBaseRouter {
  case Menu
  case Create(check: Check)
  case GetInfo(identity: ClientIdentity)
  case OpenDay
  case PrintZReport
  case Encash(amount: Double, type: EncashType)
  case CheckConnection(uuid: String)
}

extension WPBaseRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.wpBase?.baseURL ?? ""
    
    switch self {
    case .Menu:
      return "\(baseURL)/hs/Dishes/InfoDishes"
    case .Create:
      return "\(baseURL)/checks"
    case .GetInfo:
      return "\(baseURL)/hs/Client/InfoClient"
    case .OpenDay, .Encash, .PrintZReport:
      return "\(baseURL)/hs/CashDesk/Money"
    case .CheckConnection(_):
      return "\(baseURL)/hs/Base/Status"
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
    default:
      return .POST
    }
  }
  
  var encoding: Alamofire.ParameterEncoding {
    switch self {
    case .Menu:
      return .URL
    default:
      return .JSON
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
    case .OpenDay:
      return ["action": "OpenDay"]
    case .PrintZReport:
      return ["action": "PrintZReport"]
    case let .Encash(amount, type):
      return nil
    case .CheckConnection(let uuid):
      return ["terminalID": uuid]
    }
  }
}
