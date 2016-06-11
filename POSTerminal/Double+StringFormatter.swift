import Foundation

extension Double {
  func format() -> String {
    let fraction = self - Double(Int(self))
    if fraction == 0 {
      return "\(Int(self))"
    }
    
    return NSString(format: "%.2f", self) as String
  }
}