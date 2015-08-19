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
    var savedRegion: MKCoordinateRegion? = nil
    // var savedMapInfo: [ String : CLLocationDegrees ]? = nil
    
    // flag to know what action to take when an annotation in selected;
    // if editing pins, delete selected pin,
    // otherwise, segue to the selected pin's photo album
    // TODO: 3 pinch-and-zoom gestures break edit mode. need to disable them in edit mode.
    var inEditMode: Bool = false
    
    /*
    UNECESSARY
    // for use with identifying selected pins
    var totalPinsOnMap: Int = 0
    var pinIDForAnnotation = [ MKPointAnnotation : Int ]()
    */
    
    override func viewWillAppear( animated: Bool )
    {
        println( "viewWillAppear..." )
        if savedRegion != nil
        {
            println( "using the saved region..." )
            mapView.region = savedRegion!
            mapView.setCenterCoordinate( savedRegion!.center, animated: true )
        }
        else
        {
            println( "using the default region..." )
            mapView.region = defaultRegion
        }
        
        // TODO: 2-1 execute the Pin fetch request from Core Data
        
        // set the map's delegate
        mapView.delegate = self
    }
    
    override func viewDidLoad()
    {
        println( "viewDidLoad..." )
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let mapInfo = NSUserDefaults.standardUserDefaults().dictionaryForKey( "mapInfo" ) as? [ String : CLLocationDegrees ]
        {
            println( "map info exists: \( mapInfo )" )
            let centerLatitude = mapInfo[ "centerLatitude" ]!
            let centerLongitude = mapInfo[ "centerLongitude" ]!
            let spanLatDelta = mapInfo[ "spanLatitudeDelta" ]!
            let spanLongDelta = mapInfo[ "spanLongitudeDelta" ]!
            
            let newMapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: centerLatitude,
                    longitude: centerLongitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: spanLatDelta,
                    longitudeDelta: spanLongDelta
                )
            )
            
            savedRegion = newMapRegion
        }
        
        // TODO: 2-2 add all the pins, from step 2-1
        
        // add the initial action to the editPinsButton
        editPinsButton.action = "editPins:"
        
        // create the recognizer to drop pins
        let pinDropper = UILongPressGestureRecognizer(
            target: self,
            action: "dropPin:"
        )
        self.view.addGestureRecognizer( pinDropper )
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
        // get an annotation to reuse, if available
        if let newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? TravelMapAnnotationView
        {
            if let theAnnotation = Pin.getAnnotationForPinNumber( newAnnotationView.pinNumber )
            {
                newAnnotationView.annotation = theAnnotation
                return newAnnotationView
            }
            else
            {
                // but don't throw an error if it was marked for reuse
                if !TravelMapAnnotationView.reuseMe
                {
                    println( "There was an error with the Pin." )
                }
            }
        }
        // otherwise, create a new annotation
        else
        {
            let newAnnotationView = TravelMapAnnotationView(
                annotation: annotation,
                reuseIdentifier: "mapPin"
            )
            
            return newAnnotationView
        }
        
        // backup annotation to use
        return TravelMapAnnotationView(
            annotation: annotation,
            reuseIdentifier: "mapPin"
        )
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
    
    func mapView(
        mapView: MKMapView!,
        regionDidChangeAnimated animated: Bool
    )
    {
        let mapRegionCenterLatitude: CLLocationDegrees = mapView.region.center.latitude
        let mapRegionCenterLongitude: CLLocationDegrees = mapView.region.center.longitude
        let mapRegionSpanLatitudeDelta: CLLocationDegrees = mapView.region.span.latitudeDelta
        let mapRegionSpanLongitudeDelta: CLLocationDegrees = mapView.region.span.longitudeDelta
        
        // println( "map span: \( mapView.region.span.latitudeDelta ), \( mapView.region.span.longitudeDelta )" )
        
        var mapDictionary = [ String : CLLocationDegrees ]()
        mapDictionary.updateValue( mapRegionCenterLatitude, forKey: "centerLatitude" )
        mapDictionary.updateValue( mapRegionCenterLongitude, forKey: "centerLongitude" )
        mapDictionary.updateValue( mapRegionSpanLatitudeDelta, forKey: "spanLatitudeDelta" )
        mapDictionary.updateValue( mapRegionSpanLongitudeDelta, forKey: "spanLongitudeDelta" )
        
        NSUserDefaults.standardUserDefaults().setObject( mapDictionary, forKey: "mapInfo" )
    }
}
