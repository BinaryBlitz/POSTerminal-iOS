struct ClientIdentity {
  
  let code: String
  let type: Type
  
  init?(code: String, type: String) {
    guard let identityType = Type(rawValue: type) else {
      return nil
    }
    
    self.code = code
    self.type = identityType
  }

  enum Type: String {
    case TracksData
    case ScanData
    case RFIDData
  }
}
