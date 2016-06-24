struct ClientIdentity {
  
  let code: String
  let type: Type
  let readerData: [String: AnyObject]
  
  init?(code: String, type: String, readerData: [String: AnyObject]) {
    guard let identityType = Type(rawValue: type) else {
      return nil
    }
    
    self.code = code
    self.type = identityType
    self.readerData = readerData
  }

  enum Type: String {
    case TracksData
    case ScanData
    case BalanceData
  }
}
