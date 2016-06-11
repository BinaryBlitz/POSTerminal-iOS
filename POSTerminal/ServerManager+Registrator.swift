import Alamofire
import SwiftyJSON

extension ServerManager {
  
  typealias RegistratorCompletion = (response: ServerResponse<Bool, ServerError>) -> Void
  
  //MARK: - DRY stuff
  private func performRegistratorComandWith(router: ServerRouter, completion: (RegistratorCompletion)? = nil) -> Request? {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(router).validate().responseJSON { response in
        self.activityIndicatorVisible = false
        switch response.result {
        case .Success(_):
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
  
  //MARK: - General methods
  
  func openDay(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.OpenDay, completion: completion)
  }
  
  func openCashDrawer(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.OpenCashDrawer, completion: completion)
  }
  
  func print(check: Check, completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintCheck(check: check), completion: completion)
  }
  
  //MARK: - Reports
  
  func printZReport(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintZReport, completion: completion)
  }
  
  func printXReport(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintXReport, completion: completion)
  }
  
  //MARK: - Encash
  
  func encashIn(amount: Double, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.EncashIn(amount: amount), completion: completion)
  }
  
  func encashOut(amount: Double, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.EncashOut(amount: amount), completion: completion)
  }
}