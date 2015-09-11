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
    // managed properties
    @NSManaged var pin: Pin
    @NSManaged var image: UIImage?
    
    /*
    @NSManaging these properties is necessary to fix a bug:
    When visiting a photo album for the first time, if you quit the app at any time without letting all the images download from Flickr, when you relaunch the app, and visit the photo album again, the app would crash trying to download the rest of the images from Flickr. The problem was that the app needed these properties of the Photo object to create a valid URL to the image on Flickr and also to create a URL to the directory on disk where the image was being cached. These properties weren’t being @NSManaged, and so, on relaunch, the app didn’t have values for them. They are @NSManaged now, and it all seems to work.
    */
    @NSManaged var fileName: String?
    @NSManaged var filePath: NSURL?
    @NSManaged var imageURL: NSURL?
    
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
        
        // create a unique file name and path on the device for the Photo
        let imageNumber = pin.photoAlbum.count + 1
        self.fileName = "pin\( pin.pinNumber )-image\( imageNumber )"
        
        // create a URL to the image on Flickr for the photo album request
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
    
    // creates an NSURL to the file saved on the device
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
