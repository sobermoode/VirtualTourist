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
    // static var droppedPins = [ Int : Pin ]()
    static var currentPinNumber: Int = 0
    
    // instance properties
    // @NSManaged var pinNumber: Int
    // @NSManaged var coordinate: CLLocationCoordinate2D
    @NSManaged var pinLatitude: Double
    @NSManaged var pinLongitude: Double
    
    var coordinate: CLLocationCoordinate2D
        {
        return CLLocationCoordinate2D(latitude: pinLatitude, longitude: pinLongitude)
    }
    
    var photoAlbum: [ Photo? ]? // = nil
    
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
        println( "Current Pin number: \( Pin.currentPinNumber )" )
        
        // self.pinNumber = Pin.currentPinNumber
        // self.willChangeValueForKey("coordinate")
        // self.setPrimitiveValue(coordinate, forKey: "coordinate")
        // self.coordinate = coordinate
        // self.didChangeValueForKey("coordinate")
        // self.coordinate = coordinate
        pinLatitude = coordinate.latitude
        pinLongitude = coordinate.longitude
        
        // the Pin class keeps track of all active Pins
//        Pin.droppedPins.updateValue(
//            self,
//            forKey: Pin.currentPinNumber
//        )
    }
    
    override init(
        entity: NSEntityDescription,
        insertIntoManagedObjectContext context: NSManagedObjectContext?
    )
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
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
        
        Pin.currentPinNumber = pins.count
        
        return ( pins.count > 0 ) ? pins : nil
    }
    
    /*
    required init(coder aDecoder: NSCoder) {
        let pinEntity = NSEntityDescription.entityForName(
            "Pin",
            inManagedObjectContext: CoreDataStackManager.sharedInstance().managedObjectContext!
            )!
        super.init(entity: pinEntity, insertIntoManagedObjectContext: CoreDataStackManager.sharedInstance().managedObjectContext!)
    }
    */
    
    /*
    func encodeWithCoder(aCoder: NSCoder) {
        super.encode()
    }
    */
    
    class func removePin()
    {
        // remove the Pin from the model
        // Pin.droppedPins.removeValueForKey( pinNumber )
        
        // update the current Pin number
        --Pin.currentPinNumber
    }
}
