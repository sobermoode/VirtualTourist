//
//  Pin.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

@objc( Pin )

class Pin: NSManagedObject,
    MKAnnotation
{
    // class properties
    static var currentPinNumber: Int16 = 0
    
    // managed properties
    @NSManaged var pinLatitude: Double
    @NSManaged var pinLongitude: Double
    @NSManaged var pinNumber: Int16
    @NSManaged var photoAlbum: [ Photo ]
    
    // instance properties
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: pinLatitude,
            longitude: pinLongitude
        )
    }
    
    // for use with subsequent requests for new photo albums
    var nextFirstImage: Int?
    
    // we don't want to segue to the photo album too quickly;
    // see TravelMapViewController.swift
    var didGetFlickrResults: Bool = false
    
    // user deleted all the images in the photo album, so we need a new one; this flag initiates one automatically,
    // otherwise, the user will segue to an empty album, and will have to manually request a new one
    var needsNewPhotoAlbum: Bool = false
    
    init(
        coordinate: CLLocationCoordinate2D,
        context: NSManagedObjectContext
    )
    {
        // give the Pin to the context
        let pinEntity = NSEntityDescription.entityForName(
            "Pin",
            inManagedObjectContext: context
        )!
        
        super.init(
            entity: pinEntity,
            insertIntoManagedObjectContext: context
        )
        
        // update the current pin number
        ++Pin.currentPinNumber
        
        pinNumber = Pin.currentPinNumber
        pinLatitude = coordinate.latitude
        pinLongitude = coordinate.longitude
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
    
    class func fetchAllPins( completionHandler: ( fetchError: NSErrorPointer, fetchedPins: [ Pin ]? ) -> Void )
    {
        // make the fetch request
        let fetchError: NSErrorPointer = nil
        let pinsFetchRequest = NSFetchRequest( entityName: "Pin" )
        let pins = CoreDataStackManager.sharedInstance().managedObjectContext!.executeFetchRequest(
            pinsFetchRequest,
            error: fetchError
        )! as! [ Pin ]
        
        // something went wrong with the fetch request
        if fetchError != nil
        {
            completionHandler(
                fetchError: fetchError,
                fetchedPins: nil
            )
        }
            
        // the Pins have been recovered from Core Data;
        // they need to be configured before being returned to the TravelMapViewController
        else
        {
            for pin in pins
            {
                // need to set the flag, otherwise, we won't segue to the photo album
                pin.didGetFlickrResults = true
            }
            
            // set the total pin number
            Pin.currentPinNumber = Int16( pins.count )
            
            // the fetch request might have been successful but returned zero Pins?
            return ( pins.count > 0 ) ?
                completionHandler( fetchError: nil, fetchedPins: pins ) :
                completionHandler( fetchError: nil, fetchedPins: nil )
        }
    }
    
    class func removePin()
    {
        // update the current Pin number
        --Pin.currentPinNumber
    }
}
