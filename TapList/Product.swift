//
//  Product.swift
//  TapList
//
//  Created by Anthony Whitaker on 12/4/16.
//  Copyright © 2016 Anthony Whitaker. All rights reserved.
//

import Foundation

class Product {
    // 14 digit product upc. Stored as String to preserve preceeding zeros.
    var upc: String?
    var name: String?
    var listPrice: Double?
    var offerPrice: Double?
    var regularPrice: Double?
    var soldBy: TempName1?
    var orderBy: TempName2?
    // Catch-all for additional text. TODO: Refactor into specific fields?
    var detail: String?
    
    enum TempName1: String {
        case weight
    }
    
    enum TempName2: String {
        case unit
    }
    
    convenience init(upc: String, name: String,
                     listPrice: Double, offerPrice: Double? = nil,
                     detail: String,
                     soldBy: TempName1? = nil, orderBy: TempName2? = nil) {
        self.init()
        self.upc = upc
        self.name = name
        self.listPrice = listPrice
        self.offerPrice = offerPrice
        self.detail = detail
        self.soldBy = soldBy
        self.orderBy = orderBy
    }
}
