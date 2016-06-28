import Alamofire
import SwiftyJSON

extension ServerManager {
  
  typealias RegistratorCompletion = (response: ServerResponse<Bool, ServerError>) -> Void
  
  enum JobStatus: String {
    case Pending = "pending"
    case Completed = "completed"
    case Failed = "failed"
    case Canceled = "canceled"
  }
  
  func updateClientBalance(client: Client, balance: Double, completion: (response: ServerResponse<Bool, ServerError>) -> Void) {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(EquipServRouter.Update(client: client, balance: balance))
      NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (response, data, error) in
        self.activityIndicatorVisible = false
        if let httpResponse = response as? NSHTTPURLResponse {
          print("responseCode \(httpResponse.statusCode)")
          if !(httpResponse.statusCode < 300 && httpResponse.statusCode > 199) {
            completion(response: Response(error: ServerError.UnspecifiedError))
            return
          }
        }
        
        if let error = error {
          print("\(error)")
          completion(response: Response(error: ServerError(error: error)))
          return
        }
        
        do {
          let jsonResult = (try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers))
          let json = JSON(jsonResult)
          guard let jobId = json["jobId"].string else {
            completion(response: Response(error: .InvalidData))
            return
          }
          
          self.checkStatus(jobId, completion: completion)
          
          return
        } catch {
          completion(response: Response(error: .InvalidData))
          return
        }
      }
    } catch let error {
      print(error)
      completion(response: Response(error: .Unauthorized))
    }
  }
  
  private func delay(delay:Double, closure:()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
  
  func checkStatus(jobId: String, completion: (response: ServerResponse<Bool, ServerError>) -> Void) {
    checkJobWith(jobId, completion: { (response) in
      switch response.result {
      case .Success(let status):
        print(status.rawValue)
        switch status{
        case .Pending:
          self.delay(1) {
            self.checkStatus(jobId, completion: completion)
          }
        case .Completed:
          completion(response: ServerResponse<Bool, ServerError>(value: true))
        default:
          completion(response: ServerResponse<Bool, ServerError>(error: .UnspecifiedError))
        }
        
      case .Failure(let error):
        completion(response: ServerResponse<Bool, ServerError>(error: error))
      }
    })
  }
  
  func checkJobWith(jobId: String, completion: (response: ServerResponse<JobStatus, ServerError>) -> Void) {
    typealias Response = ServerResponse<JobStatus, ServerError>
    
    do {
      let request = try createRequest(EquipServRouter.CheckProcessWith(jobId: jobId))
      activityIndicatorVisible = true
      NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (response, data, error) in
        self.activityIndicatorVisible = false
        if let httpResponse = response as? NSHTTPURLResponse {
          print("responseCode \(httpResponse.statusCode)")
          if !(httpResponse.statusCode < 300 && httpResponse.statusCode > 199) {
            completion(response: Response(error: ServerError.UnspecifiedError))
            return
          }
        }
        
        if let error = error {
          print("\(error)")
          completion(response: Response(error: ServerError(error: error)))
          return
        }
        
        do {
          let jsonResult = (try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers))
          let json = JSON(jsonResult)
          guard let status = json["status"].string, jobStatus = JobStatus(rawValue: status) else {
            completion(response: Response(error: .InvalidData))
            return
          }
          completion(response: Response(value: jobStatus))
          return
        } catch {
          completion(response: Response(error: .InvalidData))
          return
        }
      }
    } catch let error {
      print(error)
      completion(response: Response(error: .Unauthorized))
    }
  }
  
  //MARK: - DRY stuff
  private func performRegistratorComandWith(router: ServerRouter, completion: (RegistratorCompletion)? = nil) -> Request? {
    typealias Response = ServerResponse<Bool, ServerError>
    
    do {
      activityIndicatorVisible = true
      let request = try createRequest(router)
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
    
    return nil
  }
  
  //MARK: - General methods
  
  func openDay(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.OpenDay, completion: completion)
  }
  
  func openDayInWP(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(WPBaseRouter.OpenDay, completion: completion)
  }
  
  func openCashDrawer(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.OpenCashDrawer, completion: completion)
  }
  
  func printCheck(check: Check, completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintCheck(check: check), completion: completion)
  }
  
  //MARK: - Reports
  
  func printZReport(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintZReport, completion: completion)
  }
  
  func printZReportInWP(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(WPBaseRouter.PrintZReport, completion: completion)
  }
  
  func printXReport(completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintXReport, completion: completion)
  }
  
  //MARK: - Encash
  
  func encash(amount: Double, type: EncashType, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.Encash(amount: amount, type: type), completion: completion)
  }
  
  func encashInWP(amount: Double, type: EncashType, completion: ((response: ServerResponse<Bool, ServerError>) -> Void)? = nil) -> Request? {
    return performRegistratorComandWith(WPBaseRouter.Encash(amount: amount, type: type), completion: completion)
  }
  
  func checkConnectionInWP(completion: (RegistratorCompletion)? = nil) -> Request? {
    guard let uuid = uuid else {
      completion?(response: ServerResponse<Bool, ServerError>(error: .InvalidData))
      return nil
    }
    return performRegistratorComandWith(WPBaseRouter.CheckConnection(uuid: uuid), completion: completion)
  }
  
  func checkConnectionInEQ(completion: (RegistratorCompletion)? = nil) -> Request? {
    guard let uuid = uuid else {
      completion?(response: ServerResponse<Bool, ServerError>(error: .InvalidData))
      return nil
    }
    return performRegistratorComandWith(EquipServRouter.CheckConnection(uuid: uuid), completion: completion)
  }
  
  func printClientBalance(client: Client, completion: (RegistratorCompletion)? = nil) -> Request? {
    return performRegistratorComandWith(EquipServRouter.PrintClientBalance(client: client), completion: completion)
  }
  
}