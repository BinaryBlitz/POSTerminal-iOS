import SwiftyJSON

protocol ServerObject {
  associatedtype ObjectType = Self
  static func createWith(json: JSON) -> ObjectType?
  var dict: [String: AnyObject]? { get }
}
