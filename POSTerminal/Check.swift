import SwiftyJSON

struct Check {
  let number: Int
  let isFiscal: Bool
  let clientId: String
  var items = []
}

extension Check: ServerObject {
  static func createWith(json: JSON) -> Check? {
    return nil
  }
  
  var json: JSON? {
    return JSON([])
  }
}