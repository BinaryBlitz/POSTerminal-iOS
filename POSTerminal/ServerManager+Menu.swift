import Foundation
import SwiftyJSON

//MARK: - Menu

extension ServerManager {
  
  func getMenu(completion: ((response: ServerResponse<[Product], ServerError>) -> Void)? = nil) {
    typealias Response = ServerResponse<[Product], ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.Menu)
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
          guard let productsData = json["products"].array else {
            completion?(response: Response(error: .InvalidData))
            return
          }
          
          let menu = productsData.flatMap { (productJSON) -> Product? in
            return Product.createWith(productJSON)
          }
          
          completion?(response: Response(value: menu))
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