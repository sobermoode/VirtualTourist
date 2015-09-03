//
//  Pin.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class Pin: NSObject, MKAnnotation
{
    // class properties
    static var droppedPins = [ Int : Pin ]()
    // static var totalPins: Int = 0 // its possible i dont need this anymore, either
    static var currentPinNumber: Int = 0
    
    // instance properties
    // var pointAnnotation: MKPointAnnotation
    // var mapPinView: TravelMapAnnotationView!
    
    var pinNumber: Int
    var coordinate: CLLocationCoordinate2D
    
    var pinName: String
    
    // TODO: uncomment after implementing the Photo class
    // var photoAlbum: [ Photo ]
    
    init( coordinate: CLLocationCoordinate2D )
    {
        // update the current pin number
        ++Pin.currentPinNumber
        
        self.pinNumber = Pin.currentPinNumber
        self.coordinate = coordinate
        
        // create an annotation
        // let newAnnotation = MKPointAnnotation()
        // newAnnotation.coordinate = coordinate
        // self.pointAnnotation = MKPointAnnotation()
        // self.pointAnnotation.coordinate = coordinate
        
        self.pinName = "Pin #\( Pin.currentPinNumber )"
        
        // create the pin view that will actually appear on the map
//        self.mapPinView = TravelMapAnnotationView(
//            annotation: newAnnotation,
//            reuseIdentifier: "mapPin"
//        )
//        self.mapPinView.pinNumber = Pin.currentPinNumber
        
        super.init()
        
        Pin.droppedPins.updateValue(
            self,
            forKey: Pin.currentPinNumber
        )
    }
    
    class func getPin( pinNumber: Int ) -> Pin!
    {
        return Pin.droppedPins[ pinNumber ]!
    }
    
    class func removePin( pinNumber: Int )
    {
        // remove the Pin from the model
        Pin.droppedPins.removeValueForKey( pinNumber )
        
        --Pin.currentPinNumber
        
        // no more annotations to reuse
//        if Pin.droppedPins.count == 0
//        {
//            TravelMapAnnotationView.resetReuseFlag()
//        }
    }
    
    class func getCurrentPinNumber() -> Int
    {
        return Pin.currentPinNumber
    }
    
    /*
    // this allows the map view in the TravelMapViewController to remove its annotations
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
    */
}
