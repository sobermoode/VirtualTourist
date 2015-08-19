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
    static var droppedPins = [ Int : Pin ]() // its possible i dont need this anymore
    static var totalPins: Int = 0
    
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
        ++Pin.totalPins
        
        // create an annotation
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = coordinate
        
        // create the pin view that will actually appear on the map
        self.mapPinView = TravelMapAnnotationView(
            annotation: newAnnotation,
            reuseIdentifier: "mapPin"
        )
        self.mapPinView.pinNumber = Pin.totalPins
        
        super.init()
        
        Pin.droppedPins.updateValue(
            self,
            forKey: Int( self.pinNumber )
        )
    }
    
    class func getTotalPins() -> Int
    {
        return Pin.totalPins
    }
}
