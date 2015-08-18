//
//  TravelMapViewController.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class TravelMapViewController: UIViewController,
    MKMapViewDelegate
{
    // outlets
    @IBOutlet weak var editPinsButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    // default map region if none exists in the NSUserDefaults
    let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 33.862237,
            longitude: -118.399519
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 3.0,
            longitudeDelta: 3.0
        )
    )
    
    // flag to know what action to take when an annotation in selected;
    // if editing pins, delete selected pin,
    // otherwise, segue to the selected pin's photo album
    var inEditMode: Bool = false
    
    override func viewWillAppear( animated: Bool )
    {
        // TODO: 1-1 get the map's region from NSUserDefaults
        // TODO: 2-1 execute the Pin fetch request from Core Data
        
        // set the map's delegate
        mapView.delegate = self
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // TODO: 1-2 set the map's region, from step 1-1
        // TODO: 2-2 add all the pins, from step 2-1
        
        // create the recognizer to drop pins
        let pinDropper = UILongPressGestureRecognizer(
            target: self,
            action: "dropPin:"
        )
        self.view.addGestureRecognizer( pinDropper )
        
        // TODO: 3 get the map region from NSUserDefaults
        // set the map region
        mapView.region = defaultRegion
    }
    
    func dropPin( sender: UILongPressGestureRecognizer )
    {
        println( "Would be dropping a pin... from sender: \( sender )" )
        
        if inEditMode
        {
            return
        }
        
        let recognizer = self.view.gestureRecognizers?.first as! UILongPressGestureRecognizer
        switch recognizer.state
        {
            case .Began:
                let mapCoordinate = mapView.convertPoint(
                    recognizer.locationInView( self.view ),
                    toCoordinateFromView: self.view
                )
                
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = mapCoordinate
                
                let newMapPin = MKPinAnnotationView(
                    annotation: newAnnotation,
                    reuseIdentifier: "mapPin"
                )
                
                let newPin = Pin( mapPin: newMapPin )
                
                mapView.addAnnotation( newAnnotation )
            
                return
            
            case .Changed:
                return
            
            case .Ended:
                return
            
            default:
                return
        }
    }
}
