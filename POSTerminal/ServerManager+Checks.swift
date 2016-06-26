import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func create(check: Check, completion: ((response: ServerResponse<String, ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<String, ServerError>
    
    do {
      activityIndicatorVisible = true
      print(WPBaseRouter.Create(check: check).parameters)
      let request = try createRequest(WPBaseRouter.Create(check: check)).validate().responseJSON { response in
        print(response.response)
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(let resultValue):
          let json = JSON(resultValue)
          if let docId = json["docID"].string {
            completion?(response: Response(value: docId))
          } else {
            completion?(response: Response(error: .InvalidData))
          }
        case .Failure(let error):
          let serverError = ServerError(error: error)
          completion?(response: Response(error: serverError))
        }
      }
      
      return request
    } catch {
      completion?(response: Response(error: .Unauthorized))
    }
    
    return nil
  }
}
