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
    var pinNumber: Int!
    
    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        println( "initing a TravelMapAnnotationView..." )
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
