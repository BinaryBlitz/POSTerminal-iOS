protocol MenuCollectionDelegate: class {
  func menuCollection(collection: MenuCollectionViewController, didSelectProduct product: Product)
  func menuCollection(collection: MenuCollectionViewController, shouldSelectProduct product: Product) -> Bool
}