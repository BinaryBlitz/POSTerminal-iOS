//
//  MenuCollectionViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 03/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit
import RealmSwift

class MenuCollectionViewController: UICollectionViewController {
  
  var menuLevelId: String = ""
  var menuPage: Results<Product>? {
    didSet {
      collectionView?.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureCollectionView()
    
    let realm = try! Realm()
    self.menuPage = realm.objects(Product).filter("parentId = '\(self.menuLevelId)'")
  }
  
  private func configureCollectionView() {
    collectionView!.backgroundColor = UIColor(red: 0.91, green: 0.95, blue: 0.98, alpha: 1)
    registerCells()
    
    //Configure layout
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 142, height: 142)
    layout.minimumInteritemSpacing = 20
    layout.minimumLineSpacing = 20
    layout.sectionInset = UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20)
    collectionView!.collectionViewLayout = layout
  }
  
  private func registerCells() {
    let productCellNib = UINib(nibName: String(ProductCollectionViewCell), bundle: nil)
    collectionView!.registerNib(productCellNib, forCellWithReuseIdentifier: "product")
    
    let categoryCellNib = UINib(nibName: String(CategoryCollectionViewCell), bundle: nil)
    collectionView!.registerNib(categoryCellNib, forCellWithReuseIdentifier: "category")
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return menuPage?.count ?? 0
  }

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    guard let product = menuPage?[indexPath.row] else { return UICollectionViewCell() }
    
    switch product.type {
    case .Item:
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("product", forIndexPath: indexPath) as! ProductCollectionViewCell
      cell.configureWith(product)
      return cell
    case .Group:
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("category", forIndexPath: indexPath) as! CategoryCollectionViewCell
      cell.configureWith(product)
      return cell
    }
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    guard let product = menuPage?[indexPath.row] else { return }
    switch product.type {
    case .Group:
      let nextPage = MenuCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
      nextPage.menuLevelId = product.id
      navigationController?.pushViewController(nextPage, animated: false)
    case .Item:
      presentAlertWithMessage("Add \(product.name)")
    }
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
