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
}
