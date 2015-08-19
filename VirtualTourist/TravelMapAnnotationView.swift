//
//  TravelMapAnnotationView.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/18/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class TravelMapAnnotationView: MKPinAnnotationView
{
    // this keeps track of the Pin on the map view
    var pinNumber: Int!
    
    override init!(
        annotation: MKAnnotation!,
        reuseIdentifier: String!
    )
    {
        super.init(
            annotation: annotation,
            reuseIdentifier: reuseIdentifier
        )
        
        self.pinNumber = Pin.getCurrentPinNumber()
    }

    required init( coder aDecoder: NSCoder )
    {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    override init( frame: CGRect )
    {
        super.init( frame: frame )
    }
}
