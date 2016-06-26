import BCColor

extension UIColor {
  
  static func elementsAndH1Color() -> UIColor {
    return ColorsManager.sharedManager.baseColor
  }
  
  static func lightOrangeColor() -> UIColor {
    return UIColor(red:1, green:0.67, blue:0, alpha:1)
  }
  
  static func h2Color() -> UIColor {
    return ColorsManager.sharedManager.baseColor.darkenByPercentage(0.25)
  }
  
  static func h3Color() -> UIColor {
    return UIColor(red:0.99, green:0.66, blue:0.67, alpha:1.0)
  }
  
  static func h4Color() -> UIColor {
    return UIColor(red:0.40, green:0.40, blue:0.48, alpha:1.0)
  }
  
  static func h5Color() -> UIColor {
    return UIColor(red:0.76, green:0.81, blue:0.85, alpha:1.0)
  }
  
  static func shadowColor() -> UIColor {
    return UIColor(red:0.67, green:0.80, blue:0.92, alpha:1.0)
  }
}