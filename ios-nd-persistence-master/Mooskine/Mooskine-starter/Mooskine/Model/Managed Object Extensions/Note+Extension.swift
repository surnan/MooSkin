//
//  Note+Extension.swift
//  Mooskine
//
//  Created by admin on 2/22/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import CoreData


extension Note {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
}

/*
 func awakeFromFetch()
 func awakeFromInsert()
 func awake(fromSnapshotEvents)
 */
