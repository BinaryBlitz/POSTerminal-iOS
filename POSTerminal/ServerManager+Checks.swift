import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func create(check: Check, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.Create(check: check)).validate().responseJSON { response in
        print(response.response)
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(let resultValue):
          let json = JSON(resultValue)
          print(json)
          completion?(response: Response(value: true))
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
