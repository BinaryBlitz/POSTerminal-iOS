//
//  MenuCollectionViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MenuCollectionViewController: UICollectionViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    collectionView!.backgroundColor = UIColor(red:0.91, green:0.95, blue:0.98, alpha:1.0)
    
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 142, height: 142)
    layout.minimumInteritemSpacing = 20
    layout.minimumLineSpacing = 20
    layout.sectionInset = UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20)
    collectionView!.collectionViewLayout = layout
    refresh()
  }
  
  func refresh() {
    ServerManager.sharedManager.getMenu { (response) in
      switch response.result {
      case .Success(let menu):
        print(menu.count)
      case .Failure(let error):
        print("error: \(error)")
      }
      self.collectionView?.reloadData()
    }
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 10
  }

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)

    // Configure the cell
    cell.backgroundColor = UIColor.h2Color()
  
    return cell
  }

  // MARK: UICollectionViewDelegate

  /*
  // Uncomment this method to specify if the specified item should be highlighted during tracking
  override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
      return true
  }
  */

  /*
  // Uncomment this method to specify if the specified item should be selected
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
      return true
  }
  */

  /*
  // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
  override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
      return false
  }

  override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
      return false
  }

  override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
  
  }
  */
}
