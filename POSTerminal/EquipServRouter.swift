import Alamofire

enum EquipServRouter {
  case OpenDay
  case EncashIn(amount: Double)
  case EncashOut(amount: Double)
  case PrintZReport
  case PrintXReport
  case OpenCashDrawer
  case PrintCheck(check: Check)
}

extension EquipServRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.equipServ?.baseURL ?? ""
    return "\(baseURL)/hs/accessories/registers"
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
  
  var parameters: [String: AnyObject]? {
    let action: String
    var params: [String: AnyObject]?
    
    switch self {
    case .OpenDay:
      action = "OpenDay"
    case .EncashIn(let amount):
      action = "Encash"
      params = ["type": 1, "amount": amount]
    case .EncashOut(let amount):
      action = "Encash"
      params = ["type": 0, "amount": amount]
    case .PrintXReport:
      action = "PrintXReport"
    case .PrintZReport:
      action = "PrintZReport"
    case .OpenCashDrawer:
      action = "OpenCashDrawer"
    case .PrintCheck(let check):
      action = "PrintCheck"
//      params =  [check.dict]
    }
    
    if let params = params {
      return ["action": action, "params": params]
    } else {
      return ["action": action]
    }
  }
}
