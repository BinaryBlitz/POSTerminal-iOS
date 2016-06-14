protocol CheckItemCellDelegate: class {
  func didTouchPlusButtonIn(cell: CheckItemTableViewCell)
  func didTouchMinusButtonIn(cell: CheckItemTableViewCell)
  func didUpdateStateFor(cell: CheckItemTableViewCell)
}
