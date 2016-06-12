import UIKit

class EquipmentManagementTableViewController: UITableViewController {
  
  @IBOutlet weak var balanceLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    balanceLabel.text = String(Settings.sharedInstance.cashBalance)
  }
  
  //MARK: - Actions
  
  @IBAction func closeButtonAction() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func updateMenu() {
    NSNotificationCenter.defaultCenter().postNotificationName(updateMenuNotification, object: nil)
  }
  
  @IBAction func openDay() {
    ServerManager.sharedManager.openDay { (response) in
      switch response.result {
      case .Success(_):
        self.presentAlertWithMessage("Кассовая смена открыта")
      case .Failure(let error):
        print(error)
        self.presentAlertWithMessage("Ошибка")
      }
    }
  }
  
  @IBAction func closeDay() {
    
  }
  
  @IBAction func printXReport() {
    
  }
  
  @IBAction func encash() {
    
  }
}
