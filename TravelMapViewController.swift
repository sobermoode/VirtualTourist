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
    
    // default map region if none exists in the NSUserDefaults;
    // the saved map info
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
    
    // flag to know what action to take when an annotation in selected;
    // if editing pins, delete selected pin,
    // otherwise, segue to the selected pin's photo album
    var inEditMode: Bool = false
    
    // this is set from the PhotoAlbumViewController to let this controller
    // know not to put the map back at the saved region
    var returningFromPhotoAlbum: Bool = false
    
    var currentPin: Pin?
    
    // MARK: Set-up functions
    
    override func viewWillAppear( animated: Bool )
    {
        println( "TravelMap viewWillAppear: There are \( Pin.getCurrentPinNumber() ) pins." )
        
        if !returningFromPhotoAlbum
        {
            if savedRegion != nil
            {
                mapView.region = savedRegion!
                mapView.setCenterCoordinate(
                    savedRegion!.center,
                    animated: true
                )
            }
            else
            {
                mapView.region = defaultRegion
            }
        }
        else
        {
            returningFromPhotoAlbum = false
        }
        
        // TODO: 2-1 execute the Pin fetch request from Core Data
        
        // set the map's delegate
        mapView.delegate = self
    }
    
    override func viewDidLoad()
    {
        println( "TravelMap viewDidLoad: There are \( Pin.getCurrentPinNumber() ) pins." )
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // check for saved map info
        if let mapInfo = NSUserDefaults.standardUserDefaults().dictionaryForKey( "mapInfo" ) as? [ String : CLLocationDegrees ]
        {
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
    
    // MARK: Button functions
    
    func editPins( sender: UIBarButtonItem )
    {
        // reveal the instruction label
        mapView.frame.origin.y -= 75.0
        
        // modify the button
        editPinsButton.title = "Done"
        editPinsButton.action = "doneEditingPins:"
        
        // disable zooming; this fixes a bug
        mapView.zoomEnabled = false
        
        // set the editing flag
        inEditMode = true
    }
    
    func doneEditingPins( sender: UIBarButtonItem )
    {
        // reset the map, button, and flag
        mapView.frame.origin.y += 75.0
        
        editPinsButton.title = "Edit"
        editPinsButton.action = "editPins:"
        
        mapView.zoomEnabled = true
        
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
                
                // create a Pin
                let newPin = Pin( coordinate: mapCoordinate )
                currentPin = newPin
                
                // add the annotation to the map
                // mapView.addAnnotation( newPin.mapPinView.annotation )
                // mapView.addAnnotation( Pin.getAnnotationForPinNumber( newPin.pinNumber ) )
                mapView.addAnnotation( newPin.pointAnnotation )
            
                return
            
            case .Changed:
                return
            
            case .Ended:
                return
            
            default:
                return
        }
    }
    
    // MARK: MKMapViewDelegate functions
    
    /*
    the way i've designed my Pin class, i encountered a bug where the coordinates sent to the PhotoAlbumViewController
    weren't always the coordinates associated with the selected pin on the map. eventually, i deduced that the reason
    was due to pin numbers (which i'd intended to be used as unique identifiers) being reused along with the annotations.
    figuring out a solution, to prevent a dequeued annotation from reusing a pin number that was already associated with
    a pin that was currently on the map, bent my brain. it took me about a day to come up with this:
    */
    func mapView(
        mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!
    ) -> MKAnnotationView!
    {
        // if there are annotations that have been recycled
        if TravelMapAnnotationView.reuseMe
        {
            // get the total number of dropped pins
            var totalPins: Int = Pin.currentPinNumber
            
            // go through each annotation view waiting to be reused
            while totalPins-- > 0
            {
                var newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as! TravelMapAnnotationView
                
                // check for the match
                if newAnnotationView.pinNumber != currentPin?.pinNumber
                {
                    continue
                }
                else
                {
                    newAnnotationView.annotation = annotation
                    
                    return newAnnotationView
                }
            }
        }
        
        // if no match is found, create a new annotation view
        var newAnnotationView = TravelMapAnnotationView(
            annotation: annotation,
            reuseIdentifier: "mapPin"
        )
        
        return newAnnotationView
        
        /*
        var newAnnotationView: TravelMapAnnotationView?
        do
        {
            newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? TravelMapAnnotationView
        }
        while newAnnotationView!.pinNumber != currentPin!.pinNumber
        
        if let newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? TravelMapAnnotationView
        {
            newAnnotationView.annotation = annotation
            
            return newAnnotationView
        }
        else
        {
            let newAnnotationView = TravelMapAnnotationView(annotation: annotation, reuseIdentifier: "mapPin" )
            newAnnotationView.pinNumber = Pin.currentPinNumber
            return newAnnotationView
        }
        */
    }
    
    /*
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
    */
    
    func mapView(
        mapView: MKMapView!,
        didSelectAnnotationView view: MKAnnotationView!
    )
    {
        if !inEditMode
        {
            // get the coordinate to pass to the PhotoAlbumViewController
            let theCoordinate = view.annotation.coordinate
            
            // segue to the photo album
            let photoAlbum = storyboard?.instantiateViewControllerWithIdentifier( "PhotoAlbum" ) as! PhotoAlbumViewController
            photoAlbum.location = theCoordinate
            
            presentViewController(
                photoAlbum,
                animated: true,
                completion: nil
            )
        }
        else
        {
            // get the selected pin
            let selectedPin = view as! TravelMapAnnotationView
            
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
        // record the map region info
        let mapRegionCenterLatitude: CLLocationDegrees = mapView.region.center.latitude
        let mapRegionCenterLongitude: CLLocationDegrees = mapView.region.center.longitude
        let mapRegionSpanLatitudeDelta: CLLocationDegrees = mapView.region.span.latitudeDelta
        let mapRegionSpanLongitudeDelta: CLLocationDegrees = mapView.region.span.longitudeDelta
        
        // create a dictionary to store in the user defaults
        var mapDictionary = [ String : CLLocationDegrees ]()
        mapDictionary.updateValue( mapRegionCenterLatitude, forKey: "centerLatitude" )
        mapDictionary.updateValue( mapRegionCenterLongitude, forKey: "centerLongitude" )
        mapDictionary.updateValue( mapRegionSpanLatitudeDelta, forKey: "spanLatitudeDelta" )
        mapDictionary.updateValue( mapRegionSpanLongitudeDelta, forKey: "spanLongitudeDelta" )
        
        // save to NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject( mapDictionary, forKey: "mapInfo" )
    }
}
