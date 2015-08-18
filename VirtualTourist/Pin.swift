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
    static var totalPins: Int = 0
    
    // instance properties
    var pinNumber: NSNumber
    var mapPin: MKPinAnnotationView
    var coordinate: CLLocationCoordinate2D
    {
        return mapPin.annotation.coordinate
    }
    // var photoAlbum: [ Photo ] uncomment after implementing Photo class
    
    init( mapPin: MKPinAnnotationView )
    {
        self.pinNumber = ++Pin.totalPins
        self.mapPin = mapPin
        
        super.init()
        
        Pin.droppedPins.updateValue( self, forKey: self.pinNumber as Int )
    }
}
