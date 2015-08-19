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
    
    // for use with identifying selected pins
    var totalPinsOnMap = 0
    var pinIDForAnnotation = [ MKPointAnnotation : Int ]()
    
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
        // don't drop pins in edit mode;
        // it messes up the view-shifting functionality
        if inEditMode
        {
            return
        }
        
        // get the long press recognizer and drop a pin if a long press starts
        let recognizer = self.view.gestureRecognizers?.first as! UILongPressGestureRecognizer
        switch recognizer.state
        {
            case .Began:
                // convert the point in the view to a map coordinate
                // and create a map annotation
                let mapCoordinate = mapView.convertPoint(
                    recognizer.locationInView( self.view ),
                    toCoordinateFromView: self.view
                )
                
                // TODO: 4 instead of creating an annotation view here, and then creating a Pin object
                // in another step, use a function on the Pin class as part of the Pin initializer,
                // and then add the annotation by returning it from the new Pin object.
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = mapCoordinate
                
                // add the annotation to the map
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
    
    // TODO: 5 don't use totalPinsOnMap; use a getter for the Pin class to find out how many pins there are
    func mapView(
        mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!
    ) -> MKAnnotationView!
    {
        if let newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? TravelMapAnnotationView
        {
            newAnnotationView.annotation = annotation
            newAnnotationView.pinNumber = ++totalPinsOnMap
            
            return newAnnotationView
        }
        else
        {
            let newAnnotationView = TravelMapAnnotationView(
                annotation: annotation,
                reuseIdentifier: "mapPin"
            )
            newAnnotationView.pinNumber = ++totalPinsOnMap
            
            return newAnnotationView
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        didSelectAnnotationView view: MKAnnotationView!
    )
    {
        let selectedPin = view as! TravelMapAnnotationView
        
        if !inEditMode
        {
            // segue to the photo album
        }
        else
        {
            // remove the selected pin
            
        }
    }
    
    /*
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        // code
    }
    */
}
