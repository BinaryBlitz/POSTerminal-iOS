import UIKit
import RealmSwift

class JournalTableViewController: UITableViewController {
  
  var items: Results<JournalItem>!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 70
    
    let realm = try! Realm()
    items = realm.objects(JournalItem).sorted("createdAt")
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! JournalItemTableViewCell
    let item = items[indexPath.row]
    cell.configureWith(item)
    return cell
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

}