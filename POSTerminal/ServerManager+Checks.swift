import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func create(check: Check, completion: ((response: ServerResponse<String, ServerError>) -> Void)? = nil) {
    typealias Response = ServerResponse<String, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.Create(check: check))
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
          let jsonResult = (try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers))
          let json = JSON(jsonResult)
          if let docId = json["docID"].string {
            completion?(response: Response(value: docId))
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
