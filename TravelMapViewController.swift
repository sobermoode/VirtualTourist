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
    var totalPinsOnMap: Int = 0
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
        
        // add the initial action to the editPinsButton
        editPinsButton.action = "editPins:"
        
        // create the recognizer to drop pins
        let pinDropper = UILongPressGestureRecognizer(
            target: self,
            action: "dropPin:"
        )
        self.view.addGestureRecognizer( pinDropper )
        
        // TODO: 3 get the map region from NSUserDefaults
        
        // set the map region
        // TODO: 4 add this as an else clause to getting the region from NSUserDefaults
        mapView.region = defaultRegion
    }
    
    func editPins( sender: UIBarButtonItem )
    {
        // reveal the instruction label
        mapView.frame.origin.y -= 75.0
        
        // modify the button
        editPinsButton.title = "Done"
        editPinsButton.action = "doneEditingPins:"
        
        // set the editing flag
        inEditMode = true
    }
    
    func doneEditingPins( sender: UIBarButtonItem )
    {
        // reset the map, button, and flag
        mapView.frame.origin.y += 75.0
        
        editPinsButton.title = "Edit"
        editPinsButton.action = "editPins:"
        
        inEditMode = false
    }
    
    func dropPin( sender: UILongPressGestureRecognizer )
    {
        // don't drop pins in edit mode;
        // it messes up the view-shifting functionality
        if inEditMode
        {
            return
        }
        
        // get the long press recognizer and drop a pin if a long press begins
        let recognizer = self.view.gestureRecognizers?.first as! UILongPressGestureRecognizer
        switch recognizer.state
        {
            case .Began:
                // convert the point in the view to a map coordinate
                // and create a map annotation
                let mapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(
                    recognizer.locationInView( self.view ),
                    toCoordinateFromView: self.view
                )
                
                let newPin = Pin( coordinate: mapCoordinate )
                
                // add the annotation to the map
                mapView.addAnnotation( newPin.mapPinView.annotation )
            
                return
            
            case .Changed:
                return
            
            case .Ended:
                return
            
            default:
                return
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!
    ) -> MKAnnotationView!
    {
        if let newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? TravelMapAnnotationView
        {
            if let theAnnotation = Pin.getAnnotationForPinNumber( newAnnotationView.pinNumber )
            {
                newAnnotationView.annotation = theAnnotation
                return newAnnotationView
            }
            else
            {
                println( "There was an error with the Pin." )
            }
        }
        else
        {
            let newAnnotationView = TravelMapAnnotationView(
                annotation: annotation,
                reuseIdentifier: "mapPin"
            )
            
            return newAnnotationView
        }
        
        return TravelMapAnnotationView(annotation: annotation, reuseIdentifier: "mapPin")
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
            // remove the selected pin from the map,
            // remove the Pin from the model
            mapView.removeAnnotation( selectedPin.annotation )
            Pin.removePin( selectedPin.pinNumber )
        }
    }
    
    /*
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        // code
    }
    */
}
