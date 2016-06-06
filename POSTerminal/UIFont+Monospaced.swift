//
//  UIFont+Monospaced.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 06/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

extension UIFont {
  
  var monospacedDigitFont: UIFont {
    let oldFontDescriptor = fontDescriptor()
    let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
    return UIFont(descriptor: newFontDescriptor, size: 0)
  }
  
}

private extension UIFontDescriptor {
  
  var monospacedDigitFontDescriptor: UIFontDescriptor {
    let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
    let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
    let fontDescriptor = self.fontDescriptorByAddingAttributes(fontDescriptorAttributes)
    return fontDescriptor
  }
  
}