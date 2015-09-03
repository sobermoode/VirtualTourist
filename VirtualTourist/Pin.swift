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
    static var currentPinNumber: Int = 0
    
    // instance properties
    var pinNumber: Int
    var coordinate: CLLocationCoordinate2D
    var photoAlbum: [ Photo? ]? = nil
    
    // for use with subsequent requests for new photo albums
    var nextFirstImage: Int?
    
    init( coordinate: CLLocationCoordinate2D )
    {
        // update the current pin number
        ++Pin.currentPinNumber
        
        self.pinNumber = Pin.currentPinNumber
        self.coordinate = coordinate
        
        super.init()
        
        // the Pin class keeps track of all active Pins
        Pin.droppedPins.updateValue(
            self,
            forKey: Pin.currentPinNumber
        )
    }
    
    class func removePin( pinNumber: Int )
    {
        // remove the Pin from the model
        Pin.droppedPins.removeValueForKey( pinNumber )
        
        // update the current Pin number
        --Pin.currentPinNumber
    }
}
