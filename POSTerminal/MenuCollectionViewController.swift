import UIKit
import RealmSwift

let reloadMenuNotification = "reloadMenuNotification"

class MenuCollectionViewController: UICollectionViewController {
  
  var menuLevelId: String = ""
  var menuPage: Results<Product>?
  
  weak var delegate: MenuCollectionDelegate?
  weak var navigationProvider: MenuNavigationProvider!

  override func viewDidLoad() {
    super.viewDidLoad()

    configureCollectionView()
    
    let realm = try! Realm()
    self.menuPage = realm.objects(Product).filter("parentId = '\(self.menuLevelId)'")
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.reloadData), name: reloadMenuNotification, object: nil)
    
    let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeBack(_:)))
    view.addGestureRecognizer(swipeGesture)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func swipeBack(gestureRecognizer: UISwipeGestureRecognizer) {
    navigationProvider.popViewController()
  }
  
  @objc private func reloadData() {
    collectionView?.reloadData()
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
      nextPage.delegate = delegate
      nextPage.navigationProvider = navigationProvider
      nextPage.menuLevelId = product.id
      navigationController?.pushViewController(nextPage, animated: false)
    case .Item:
      if delegate!.menuCollection(self, shouldSelectProduct: product) {
        OrderManager.currentOrder.append(product)
      } else {
        presentAlertWithMessage("Нельзя добавлять товары из скидочной категории с обычными")
      }
    }
    
    delegate?.menuCollection(self, didSelectProduct: product)
  }
  
}
