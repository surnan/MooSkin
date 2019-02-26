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
    
    var backgroundContext: NSManagedObjectContext!
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer.init(name: modelName)
        ///* different ways to set background context tasks
        //long-term background context
        //        let backgroundContext = persistentContainer.newBackgroundContext()
        
        
        //UIKit must be done on the main queue because it's not thread safe
        
        /*
         //  ONE of the below perform calls should ALWAYS be utilized on your core data context tasks
         //
         //multiple temporary backgroundContexts - this can be better.  Lets CoreData parallel the changes if it improves efficiency
         persistentContainer.performBackgroundTask { (context) in
         doSomeSlowWork()
         try? context.save()
         }
         
         
         //'perform' will correctly call the appropriate queue for the context
         viewContext.perform {
         doSomeSlowWork()
         }
         
         //perform work synchronously on correct queue
         viewContext.performAndWait {
         doSomeSlowWork()
         }
         */
    }
    
    
    //FetchResultsController automatically observe notifications on viewContext & update their tableviews
    //NotesDetailsViewController does NOT have fetchedResultsController
    //    //the automatic merging setup below means viewContext will merge in updates after the backgroundContext saves
    //    // & it will generate notifications when it does
    //      //NotesDetailsViewController will listen for these notifications
    
    func configureContexts(){
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        
        //We're giving the priority to 'backgroundContext' when it conflicts with 'viewContext'
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump  //prefers it's own properties if there's conflict
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump       //prefers store if there's conflict
        
        
    }
    
    func load(completion: (()->Void)? = nil){
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            guard error == nil else {
                fatalError((error?.localizedDescription)!)
            }
        }
        //        autoSaveViewContext(interval: 3)  //workds
        //        autoSaveViewContext()             //workds
        self.configureContexts()
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
