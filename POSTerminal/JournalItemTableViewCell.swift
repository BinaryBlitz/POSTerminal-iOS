import UIKit

class JournalItemTableViewCell: UITableViewCell {
  
  @IBOutlet weak var clientCodeLabel: UILabel!
  @IBOutlet weak var docIdLabel: UILabel!
  @IBOutlet weak var checkNumberLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  
  func configureWith(item: JournalItem) {
    clientCodeLabel.text = "Клинет: \(item.clientCode)"
    checkNumberLabel.text = "#\(item.number)"
    dateLabel.text = format(item.createdAt)
    amountLabel.text = "\(item.amount.format()) р"
    if item.docId == "" {
      docIdLabel.text = ""
    } else {
      docIdLabel.text = "ID: \(item.docId)"
    }
  }
  
  private func format(date: NSDate) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
    return formatter.stringFromDate(date)
  }
  
}
