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
  case PrintClientBalance(client: Client)
  case Update(client: Client, balance: Double)
}

extension EquipServRouter: ServerRouter {
  
  var path: String {
    let baseURL = Settings.sharedInstance.equipServ?.baseURL ?? ""
    switch self {
    case .RegisterDevice(_):
      return "\(baseURL)/hs/accessories/mobile-device"
    case .CheckConnection(_):
      return "\(baseURL)/hs/Base/Status"
    case .Update(_, _):
      return "\(baseURL)/hs/RFID/WriteData"
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
      let orderTotal = check.payments.reduce(0, combine: { (sum, payment) -> Double in
        return sum + payment.amount
      })
      
      let balance = ClientManager.currentClient?.balance ?? 0.0
      let newBalance = balance - orderTotal
      
      params =  [
        "footerText": "Старый баланс: \(balance.format())\nОстаток: \(newBalance.format())",
        "type": 0,
        "isFiscal": check.isFiscal,
        "items": check.items.flatMap { (item) -> [String: AnyObject]? in
          return [
            "type": "fiscal",
            "name": item.product.name,
            "qty": item.quantity,
            "price": item.product.price.value ?? 0,
            "amount": item.totalPrice,
            "valueAddedTax": item.product.valueAddedTax
          ]
        },
        "payments": check.payments.flatMap { (payment) -> [String: AnyObject]? in
          return payment.dict
        }
      ]
    case .PrintClientBalance(let client):
      action = "PrintRecept"
      params =  [
        "isFiscal": false,
        "items": [["type": "text", "text": "Баланс: \(client.balance.format())"]]
      ]
    case .RegisterDevice(let url):
      return ["notify": url]
    case .CheckConnection(let uuid):
      return ["terminalID": uuid]
    case let .Update(client, balance):
      guard let identity = client.identity else {
        return nil
      }
      var jsonObject = identity.readerData
      jsonObject["balance"] = balance
      return jsonObject
    }
    
    if let uuid = uuid {
      if let params = params {
        return ["action": action, "params": params, "terminalID": uuid]
      } else {
        return ["action": action, "terminalID": uuid]
      }
    } else {
      return nil
    }
  }
}
