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
    @NSManaged var image: UIImage
    
    var fileName: String?
    var filePath: NSURL?
    
    init(
        pin: Pin,
        imageData: NSData,
        context: NSManagedObjectContext
    )
    {
        let photoEntity = NSEntityDescription.entityForName(
            "Photo",
            inManagedObjectContext: context
        )!
        
        super.init(
            entity: photoEntity,
            insertIntoManagedObjectContext: context
        )
        
        self.pin = pin
        self.image = UIImage( data: imageData )!
        
        let imageNumber = pin.photoAlbum.count + 1
        self.fileName = "pin\( pin.pinNumber )-image\( imageNumber )"
        self.filePath = createImageFileURL()
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
    
    func createImageFileURL() -> NSURL
    {
        let directoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [ directoryPath, self.fileName! ]
        
        return NSURL.fileURLWithPathComponents( pathArray )!
    }
}
