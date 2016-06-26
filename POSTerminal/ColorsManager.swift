let UpdateColorsNotification = "UpdateColorsNotification"

class ColorsManager {
  static var sharedManager = ColorsManager()
  
  private var defaultColor = UIColor(red:0.99, green:0.55, blue:0.22, alpha:1.0)
  var baseColor: UIColor {
    didSet {
      NSNotificationCenter.defaultCenter().postNotificationName(UpdateColorsNotification, object: nil)
    }
  }
  
  init() {
    baseColor = defaultColor
  }
}
