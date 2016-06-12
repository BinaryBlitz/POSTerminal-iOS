import Alamofire
import SwiftyJSON

extension ServerManager {
  
  func registerDeviceWithCallbackURL(url: String, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(EquipServRouter.RegisterDevice(url: url)).validate().responseJSON { response in
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(let resultValue):
          let json = JSON(resultValue)
          NSLog("\(json)")
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