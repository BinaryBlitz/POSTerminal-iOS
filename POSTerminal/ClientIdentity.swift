struct ClientIdentity {
  
  let code: String
  let type: Type

  enum Type: String {
    case TacksData
    case ScanData
    case RFIDData
  }
}
