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

class Pin: NSManagedObject, MKAnnotation
{
    // class properties
    static var currentPinNumber: Int = 0
    
    // instance properties
    @NSManaged var pinLatitude: Double
    @NSManaged var pinLongitude: Double
    @NSManaged var photoAlbum: [ Photo! ]
    
    var pinNumber: Int?    
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: pinLatitude,
            longitude: pinLongitude
        )
    }
    
    // for use with subsequent requests for new photo albums
    var nextFirstImage: Int?
    
    init(
        coordinate: CLLocationCoordinate2D,
        context: NSManagedObjectContext
    )
    {
        println( "Creating a new Pin..." )
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
    
    class func fetchAllPins() -> [ Pin ]?
    {
        println( "fetching all pins..." )
        let fetchError: NSErrorPointer = nil
        
        let pinsFetchRequest = NSFetchRequest( entityName: "Pin" )
        
        let pins = CoreDataStackManager.sharedInstance().managedObjectContext!.executeFetchRequest(
            pinsFetchRequest,
            error: fetchError
        )! as! [ Pin ]
        println( "pins.count: \( pins.count )" )
        
        if fetchError != nil
        {
            println( "There was an error fetching the pins from Core Data: \( fetchError )." )
        }
        
        for pin in pins
        {
            println( "This Pin has \( pin.photoAlbum.count ) Photos." )
        }
        
        Pin.currentPinNumber = pins.count
        
        return ( pins.count > 0 ) ? pins : nil
    }
    
    class func removePin()
    {
        // update the current Pin number
        --Pin.currentPinNumber
    }
}
