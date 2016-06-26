import UIKit
import Fabric
import Crashlytics
import GCDWebServer
import SwiftyJSON
import RealmSwift
import BCColor

var uuid: String?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  
  var gcdWebServer: GCDWebServer?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Fabric.with([Crashlytics.self])
    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    Settings.loadFormUserDefaults()
    Settings.sharedInstance.wpBase = Host(baseURL: "http://arma.ngslab.ru:28081/WPServ", login: "I.Novikov", password: "123456789")
    Settings.sharedInstance.equipServ = Host(baseURL: "http://arma.ngslab.ru:28081/EquipServ", login: "", password: "")
    ClientManager.currentClient = Client(id: "afcb9338-0892-11e6-93fd-525400643a93", code: "381", name: "Стол 3", balance: 32000)
    
    ColorsManager.sharedManager.baseColor = UIColor.colorWithHex("#2196F3")!
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    if let id = userDefaults.objectForKey("ApplicationUniqueIdentifier") as? String {
      uuid = id
    } else {
      let UUID = NSUUID().UUIDString
      userDefaults.setObject(UUID, forKey: "ApplicationUniqueIdentifier")
      userDefaults.synchronize()
      uuid = UUID
    }
    
    print(uuid!)
    
    startLocalServer()
    
    configureRealm()
    
    return true
  }
  
  func configureRealm() {
    let realmDefaultConfig = Realm.Configuration(
      schemaVersion: 4,
      migrationBlock: { migration, oldSchemaVersion in
      }
    )
    Realm.Configuration.defaultConfiguration = realmDefaultConfig
  }
  
  
  func startLocalServer() {
    gcdWebServer = GCDWebServer()
    
    if let server = gcdWebServer {
      server.addHandlerForMethod("GET", path: "/", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse in
        return GCDWebServerResponse(redirect: NSURL(string: "http://yesno.wtf"), permanent: false)
      }
      
      server.addHandlerForMethod("POST", path: "/codes", requestClass: GCDWebServerDataRequest.self) { (request) -> GCDWebServerResponse! in
        let req = request as! GCDWebServerDataRequest
        let json = JSON(req.jsonObject)
        guard let type = json["type"].string, code = json["code"].string, jsonObject = json.dictionaryObject,
            clientIdentity = ClientIdentity(code: code, type: type, readerData: jsonObject) else {
          return GCDWebServerResponse(statusCode: 400)
        }
        print(jsonObject)
        
        ServerManager.sharedManager.getInfoFor(clientIdentity) { (response) in
          switch response.result {
          case .Success(let client):
            ClientManager.currentClient = client
            NSNotificationCenter.defaultCenter().postNotificationName(clientUpdatedNotification, object: nil)
          case .Failure(let error):
            print(error)
          }
        }
        
        return GCDWebServerResponse(statusCode: 200)
      }
      
      server.startWithPort(8080, bonjourName: nil)
      print("Visit \(server.serverURL) in your web browser")
    }
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

