//
//  MenuNavigationProvider.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 11/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

protocol MenuNavigationProvider: class {
  func popViewController()
  func popToRootViewController()
}
