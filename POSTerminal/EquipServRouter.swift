import Alamofire

enum EquipServRouter {
  case OpenDay
  case Encash(amount: Double, type: EncashType)
  case PrintZReport
  case PrintXReport
  case OpenCashDrawer
  case PrintCheck(check: Check)
  case RegisterDevice(url: String)
  case CheckConnection(uuid: String)
}

extension EquipServRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.equipServ?.baseURL ?? ""
    switch self {
    case .RegisterDevice(_):
      return "\(baseURL)/hs/accessories/mobile-device"
    case .CheckConnection(_):
      return "\(baseURL)/hs/Base/Status"
    default:
      return "\(baseURL)/hs/accessories/registers"
    }
  }
  
  var login: String? {
    return Settings.sharedInstance.equipServ?.login
  }
  
  var password: String? {
    return Settings.sharedInstance.equipServ?.password
  }
  
  var method: Alamofire.Method {
    return .POST
  }
  
  var encoding: Alamofire.ParameterEncoding {
    return .JSON
  }
  
  var parameters: [String: AnyObject]? {
    let action: String
    var params: [String: AnyObject]?
    
    switch self {
    case .OpenDay:
      action = "OpenDay"
    case let .Encash(amount, type):
      action = "Encash"
      params = ["type": type.value, "amount": amount]
    case .PrintXReport:
      action = "PrintXReport"
    case .PrintZReport:
      action = "PrintZReport"
    case .OpenCashDrawer:
      action = "OpenCashDrawer"
    case .PrintCheck(let check):
      action = "PrintCheck"
//      params =  [check.dict]
    case .RegisterDevice(let url):
      return ["notify": url]
    case .CheckConnection(let uuid):
      return ["terminalID": uuid]
    }
    
    if let uuid = uuid {
      if let params = params {
        return ["action": action, "params": params, "treminalID": uuid]
      } else {
        return ["action": action, "treminalID": uuid]
      }
    } else {
      return nil
    }
  }
}
