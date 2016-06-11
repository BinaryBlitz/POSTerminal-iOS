import Alamofire

protocol ServerRouter {
  var path: String { get }
  var method: Alamofire.Method { get }
  var encoding: Alamofire.ParameterEncoding { get }
  var parameters: [String: AnyObject]? { get }
  var login: String? { get }
  var password: String? { get }
}
