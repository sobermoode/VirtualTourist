//
//  Pin.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class Pin: NSObject
{
    // class properties
    static var droppedPins = [ Int : Pin ]()
    static var totalPins: Int = 0 // its possible i dont need this anymore, either
    static var currentPinNumber: Int = 0
    
    // instance properties
    var mapPinView: TravelMapAnnotationView
    // TODO: make sure these computed properties are ever actually needed anywhere in the project
    var pinNumber: Int!
    {
        return mapPinView.pinNumber
    }
    var coordinate: CLLocationCoordinate2D
    {
        return mapPinView.annotation.coordinate
    }
    
    // TODO: uncomment after implementing the Photo class
    // var photoAlbum: [ Photo ]
    
    init( coordinate: CLLocationCoordinate2D )
    {
        // update the total number of pins on the map
        // ++Pin.totalPins
        
        // update the current pin number
        ++Pin.currentPinNumber
        
        // create an annotation
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = coordinate
        
        // create the pin view that will actually appear on the map
        self.mapPinView = TravelMapAnnotationView(
            annotation: newAnnotation,
            reuseIdentifier: "mapPin"
        )
        self.mapPinView.pinNumber = Pin.currentPinNumber
        
        super.init()
        
        Pin.droppedPins.updateValue(
            self,
            forKey: Pin.currentPinNumber
        )
    }
    
    class func removePin( pinNumber: Int )
    {
        // remove the Pin from the model
        Pin.droppedPins.removeValueForKey( pinNumber )
        
        // no more annotations to reuse
        if Pin.droppedPins.count == 0
        {
            TravelMapAnnotationView.resetReuseFlag()
        }
        
        // update the total number of pins on the map
        // --Pin.totalPins
    }
    
    class func getCurrentPinNumber() -> Int
    {
        return Pin.currentPinNumber
    }
    
    class func getAnnotationForPinNumber( pinNumber: Int ) -> MKAnnotation?
    {
        if let thePin = Pin.droppedPins[ pinNumber ]
        {
            return thePin.mapPinView.annotation
        }
        else
        {
            if !TravelMapAnnotationView.reuseMe
            {
                println( "There was an error finding that Pin." )
                return nil
            }
        }
        
        return nil
    }
}
