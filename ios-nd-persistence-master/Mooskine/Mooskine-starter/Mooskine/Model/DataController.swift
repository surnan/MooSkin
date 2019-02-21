//
//  DataController.swift
//  Mooskine
//
//  Created by admin on 2/21/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer.init(name: modelName)
    }
    
    
    func load(completion: (()->Void)? = nil){
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            guard error == nil else {
                fatalError((error?.localizedDescription)!)
            }
        }
        completion?()
    }
}
