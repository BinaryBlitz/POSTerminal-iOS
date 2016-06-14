enum EncashType {
  case Out
  case In
  
  var value: Int {
    if self == .Out { return 0 }
    return 1
  }
}
