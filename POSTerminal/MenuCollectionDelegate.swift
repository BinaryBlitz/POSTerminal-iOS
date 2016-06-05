//
//  MenuCollectionDelegate.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 05/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

protocol MenuCollectionDelegate: class {
  func menuCollection(collection: MenuCollectionViewController, didSelectProdict product: Product)
}