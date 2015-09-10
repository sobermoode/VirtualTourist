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
    @NSManaged var image: UIImage?
    
    var fileName: String?
    var filePath: NSURL?
    var imageURL: NSURL?
    
    init(
        pin: Pin,
        imageInfo: [ String : AnyObject ],
        context: NSManagedObjectContext
    )
    {
        // give the Photo to the context
        let photoEntity = NSEntityDescription.entityForName(
            "Photo",
            inManagedObjectContext: context
        )!
        
        super.init(
            entity: photoEntity,
            insertIntoManagedObjectContext: context
        )
        
        // set the Pin relationship
        self.pin = pin
        // self.image = UIImage( data: imageData )!
        
        // create a unique file name and path on the device for the Photo
        let imageNumber = pin.photoAlbum.count + 1
        self.fileName = "pin\( pin.pinNumber )-image\( imageNumber )"
        // self.filePath = createImageFileURL()
        
        // create a URL to the image on Flickr for a subsequent request
        self.imageURL = urlForImageInfo( imageInfo )
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
    
    // creates a URL to the file saved on the device
    func createImageFileURL()
    {
        let directoryPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[0] as! String
        let pathArray = [ directoryPath, self.fileName! ]
        
        self.filePath = NSURL.fileURLWithPathComponents( pathArray )!
    }
    
    // creates an NSURL to an actual image from an info dictionary returned from Flickr
    func urlForImageInfo( imageInfo: [ String : AnyObject ] ) -> NSURL!
    {
        let farmID = imageInfo[ "farm" ] as! Int
        let serverID = imageInfo[ "server" ] as! String
        let photoID = imageInfo[ "id" ] as! String
        let secret = imageInfo[ "secret" ] as! String
        
        let imageURLString = "https://farm\( farmID ).staticflickr.com/\( serverID )/\( photoID )_\( secret ).jpg"
        
        return NSURL( string: imageURLString )!
    }
}
