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
        //        autoSaveViewContext(interval: 3)  //workds
        //        autoSaveViewContext()             //workds
        completion?()
    }
}


extension DataController {
    func autoSaveViewContext(interval: TimeInterval = 30){
        
        print("firing autoSave")
        
        guard interval > 0 else {
            print("Can not set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }


        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
