//
//  PROUpgradeProduct.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import StoreKit

public struct PROUpgradeProduct {
    
    public static let iap = "com.aww.quickpostig.proupgradeiap"
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [PROUpgradeProduct.iap]
    public static let store = IAPHelper(productIds: PROUpgradeProduct.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
