import UIKit

class JournalItemTableViewCell: UITableViewCell {
  
  @IBOutlet weak var clientCodeLabel: UILabel!
  @IBOutlet weak var checkNumberLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  
  func configureWith(item: JournalItem) {
    clientCodeLabel.text = "Клинет: \(item.clientCode)"
    checkNumberLabel.text = "#\(item.number)"
    dateLabel.text = format(item.createdAt)
    amountLabel.text = "\(item.amount.format()) р"
  }
  
  private func format(date: NSDate) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
    return formatter.stringFromDate(date)
  }
  
}
