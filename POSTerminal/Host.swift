import Foundation

class Host: NSObject, NSCoding {
  
  let baseURL: String
  let login: String
  let password: String
  
  init(baseURL: String, login: String, password: String) {
    self.baseURL = baseURL
    self.login = login
    self.password = password
    super.init()
  }
  
  internal required init(coder aDecoder: NSCoder) {
    baseURL = aDecoder.decodeObjectForKey("baseURL") as! String
    login = aDecoder.decodeObjectForKey("login") as! String
    password = aDecoder.decodeObjectForKey("password") as! String
    super.init()
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(baseURL, forKey: "baseURL")
    aCoder.encodeObject(login, forKey: "login")
    aCoder.encodeObject(password, forKey: "password")
  }
}