//
//  Photo.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 9/2/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class Photo: NSObject
{
    var pin: Pin!
    
    var image: UIImage!
    
    init( pin: Pin, imageData: NSData )
    {
        self.pin = pin
        self.image = UIImage( data: imageData )
    }
}
