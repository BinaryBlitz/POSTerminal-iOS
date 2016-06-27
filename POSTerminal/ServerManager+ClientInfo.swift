import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func getInfoFor(identity: ClientIdentity, completion: ((response: ServerResponse<Client, ServerError>) -> Void)? = nil) {
    typealias Response = ServerResponse<Client, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.GetInfo(identity: identity))
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
          return
        }
        
        do {
          guard let data = data else {
            completion?(response: Response(error: .InvalidData))
            return
          }
          
          let jsonResult = (try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers))
          let json = JSON(jsonResult)
          if let client = Client.createWith(json) {
            var identifiedClient = client
            identifiedClient.identity = identity
            completion?(response: Response(value: identifiedClient))
          } else {
            completion?(response: Response(error: .InvalidData))
          }
          return
        } catch {
          completion?(response: Response(error: .InvalidData))
          return
        }
      }
    } catch let error {
      print(error)
      completion?(response: Response(error: .Unauthorized))
    }
  }
}