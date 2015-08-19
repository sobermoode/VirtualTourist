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
    
    // this prevents errors when reusing annotations
    static var reuseMe: Bool = false
    
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
    
    // tells the TravelMapViewController not to throw an error when looking for a cell to reuse
    override func prepareForReuse()
    {
        TravelMapAnnotationView.reuseMe = true
    }
    
    class func resetReuseFlag()
    {
        TravelMapAnnotationView.reuseMe = false
    }
}
