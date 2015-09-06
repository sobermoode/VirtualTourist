//
//  Photo.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 9/2/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import CoreData

@objc( Photo )

class Photo: NSManagedObject
{
    @NSManaged var pin: Pin
    @NSManaged var imageData: NSData
    // @NSManaged var image: UIImage?
    
    init(
        pin: Pin,
        imageData: NSData,
        context: NSManagedObjectContext
    )
    {
        println( "Creating a Photo..." )
        println( "There are now \( pin.photoAlbum.count ) Photos in the album." )
        let photoEntity = NSEntityDescription.entityForName(
            "Photo",
            inManagedObjectContext: context
        )!
        
        super.init(
            entity: photoEntity,
            insertIntoManagedObjectContext: context
        )
        
        self.pin = pin
        self.imageData = imageData
        // self.imageData = NSData(data: imageData)
        // self.image = UIImage( data: imageData )
    }
    
    override init(
        entity: NSEntityDescription,
        insertIntoManagedObjectContext context: NSManagedObjectContext?
    )
    {
        super.init(
            entity: entity,
            insertIntoManagedObjectContext: context
        )
    }
}
