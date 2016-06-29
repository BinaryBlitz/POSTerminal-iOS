import Alamofire

class ServerManager {
  
  static let sharedManager = ServerManager()
  
  var activityIndicatorVisible: Bool {
    get {
      return UIApplication.sharedApplication().networkActivityIndicatorVisible
    }
    set {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = newValue
    }
  }
  
  func createRequest(router: ServerRouter) throws -> NSURLRequest {
    guard let login = router.login, password = router.password else {
      throw ServerError.Unauthorized
    }
    
    let url = NSURL(string: router.path)!
    
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = router.method.rawValue
    request.timeoutInterval = 60
    request.addValue(base64CredentialsFor(login, and: password), forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    if let parameters = router.parameters {
      let bodyData = try! NSJSONSerialization.dataWithJSONObject(parameters, options: .PrettyPrinted)
      request.HTTPBody = bodyData
    }
    
    return request
  }
  
  private func base64CredentialsFor(login: String, and password: String) -> String {
    let credentialData = "\(login):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
    let base64Credentials = credentialData.base64EncodedStringWithOptions([])
    return "Basic \(base64Credentials)"
  }
}
