import UIKit
import Fabric
import Crashlytics
import SwiftyJSON
import RealmSwift
import BCColor


var uuid: String?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  
  // Server for connections over cabel
  var swifterServer: HttpServer?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Fabric.with([Crashlytics.self])
    
    NSURLProtocol.registerClass(RedSocketURLProtocol.self)
    RedSocketManager.sharedInstance().configureNetworkInterface("0.0.0.0", gateway: "0.0.0.0", netmask: "0.0.0.0", dns: nil)
    
    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    Settings.loadFormUserDefaults()
//    Settings.sharedInstance.wpBase = Host(baseURL: "http://arma.ngslab.ru:28081/WPServ", login: "I.Novikov", password: "123456789")
//    Settings.sharedInstance.equipServ = Host(baseURL: "http://arma.ngslab.ru:28081/EquipServ", login: "", password: "")
//    ClientManager.currentClient = Client(id: "afcb9338-0892-11e6-93fd-525400643a93", code: "381", name: "Стол 3", balance: 32000)
//    ClientManager.currentClient?.identity = ClientIdentity(code: "381", type: "TracksData", readerData: ["clientRef": "afcb9338-0892-11e6-93fd-525400643a93",
//      "clientName": "Стол 3",
//      "balance": 6000,
//      "clientCode": "381"])
    
    if let colorString = Settings.sharedInstance.baseColorHex, color = UIColor.colorWithHex(colorString) {
      ColorsManager.sharedManager.baseColor = color
    }
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    if let id = userDefaults.objectForKey("ApplicationUniqueIdentifier") as? String {
      uuid = id
    } else {
      let UUID = NSUUID().UUIDString
      userDefaults.setObject(UUID, forKey: "ApplicationUniqueIdentifier")
      userDefaults.synchronize()
      uuid = UUID
    }
    
    print(uuid)
    
    startSwifterServer()
    
    configureRealm()
    
    return true
  }
  
  func configureRealm() {
    let realmDefaultConfig = Realm.Configuration(
      schemaVersion: 7,
      migrationBlock: { migration, oldSchemaVersion in
      }
    )
    Realm.Configuration.defaultConfiguration = realmDefaultConfig
  }
  
  func startSwifterServer() {
    let server = HttpServer()
    server["/codes"] = { (request: HttpRequest) -> HttpResponse in
      let parameters = request.parseUrlencodedForm().toDictionary { ($0.0, $0.1) }
      let json = JSON(parameters)
      guard let type = json["type"].string, code = json["code"].string, jsonObject = json.dictionaryObject,
          clientIdentity = ClientIdentity(code: code, type: type, readerData: jsonObject) else {
        return HttpResponse.BadRequest(.Json(["message": "type or code are missing in parameters"]))
      }
      
      ServerManager.sharedManager.getInfoFor(clientIdentity) { (response) in
        dispatch_async(dispatch_get_main_queue()) {
          switch response.result {
          case .Success(let client):
            ClientManager.currentClient = client
            NSNotificationCenter.defaultCenter().postNotificationName(clientUpdatedNotification, object: nil)
          case .Failure(let error):
            let alert = UIAlertController(title: "Ошибка", message: "\(error)", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            NSNotificationCenter.defaultCenter().postNotificationName(presentViewControllerNotification, object: nil, userInfo: ["viewController": alert])
            print(error)
          }
        }
        }
      return HttpResponse.OK(.Json(["message": "OK!"]))
    }
    
    try! server.start(9080, forceIPv4: true)
    self.swifterServer = server
    
    print(RedSocketManager.sharedInstance().ipAddress())
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}

