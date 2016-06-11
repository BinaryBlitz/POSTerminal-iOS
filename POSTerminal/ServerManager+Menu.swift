import Alamofire
import SwiftyJSON

//MARK: - Menu

extension ServerManager {
  func getMenu(completion: ((response: ServerResponse<[Product], ServerError>) -> Void)? = nil) -> Request? {
    typealias Response = ServerResponse<[Product], ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(WPBaseRouter.Menu).validate().responseJSON { response in
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(let resultValue):
          let json = JSON(resultValue)
          guard let productsData = json["products"].array else {
            completion?(response: Response(error: .InvalidData))
            return
          }
          
          let menu = productsData.flatMap { (productJSON) -> Product? in
            return Product.createWith(productJSON)
          }
          
          completion?(response: Response(value: menu))
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