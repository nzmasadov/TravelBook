//
//  UserModel.swift
//  TravelBook
//
//  Created by Nazim Asadov on 17.02.22.
//

import Foundation

class UserSingleton {
    static let sharedInstance = UserSingleton()
    
    var selectedTitle = String()
    var selectedId: UUID?
    
    // ListViewController
    var annotationTitle = String()
    var annotationSubtitle = String()
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    // MainViewController
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    private init () {}
}
