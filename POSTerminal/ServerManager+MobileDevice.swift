import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func registerDeviceWithCallbackURL(url: String, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(EquipServRouter.RegisterDevice(url: url))
      NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (response, data, error) in
        self.activityIndicatorVisible = false
        if let httpResponse = response as? NSHTTPURLResponse {
          print("responseCode \(httpResponse.statusCode)")
          if !(httpResponse.statusCode < 300 && httpResponse.statusCode > 199) {
            completion?(response: Response(error: ServerError.UnspecifiedError))
            return
          }
        }
        
        if let error = error {
          print("\(error)")
          completion?(response: Response(error: ServerError(error: error)))
        } else {
          completion?(response: Response(value: true))
        }
      }
    } catch let error {
      print(error)
      completion?(response: Response(error: .Unauthorized))
    }
  }
}