//
//  TravelMapViewController.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelMapViewController: UIViewController,
    MKMapViewDelegate
{
    // outlets
    @IBOutlet weak var editPinsButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    // default map region if none exists in the NSUserDefaults;
    // hermosa beach, ca, my hometown 😁
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
    
    // this is set from the PhotoAlbumViewController to let this controller know not to put the map back at the saved region
    // and to deselect any previously selected pin
    var returningFromPhotoAlbum: Bool = false
    var selectedPin: MKAnnotation?
    
    lazy var sharedContext: NSManagedObjectContext =
    {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    // MARK: Set-up functions
    
    override func viewWillAppear( animated: Bool )
    {
        // set the map;
        // set it to the saved region, if restarting the app,
        // otherwise, keep the map where it was prior to segueing to the PhotoAlbumViewController
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
            // deslect the pin; otherwise, you can't select it again consecutively without deslecting it by tapping an empty map region
            mapView.deselectAnnotation( selectedPin!, animated: true )
            
            // reset the flag
            returningFromPhotoAlbum = false
        }
    }
    
    override func viewDidLoad()
    {
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
        if let allPins = Pin.fetchAllPins()
        {
            mapView.addAnnotations( allPins )
        }
        
        // add the initial action to the editPinsButton
        editPinsButton.action = "editPins:"
        
        // create the recognizer to drop pins
        let pinDropper = UILongPressGestureRecognizer(
            target: self,
            action: "dropPin:"
        )
        self.view.addGestureRecognizer( pinDropper )
        
        // set the map's delegate
        mapView.delegate = self
    }
    
    // MARK: Button functions
    
    func editPins( sender: UIBarButtonItem )
    {
        // reveal the instruction label
        mapView.frame.origin.y -= 75.0
        
        // modify the button
        editPinsButton.title = "Done"
        editPinsButton.action = "doneEditingPins:"
        
        // disable scrolling and zooming; these both caused bugs in edit mode
        // (not an ideal solution, i know)
        mapView.scrollEnabled = false
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
        
        mapView.scrollEnabled = true
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
                let newPin = Pin( coordinate: mapCoordinate, context: sharedContext )
                
                // make the Flickr request for the photo results
                getFlickrResults( newPin )
                
                // add the pin to the map
                mapView.addAnnotation( newPin )
                
                // save the Pin to the context
                CoreDataStackManager.sharedInstance().saveContext()
            
                return
            
            // i couldn't quite figure out dragging functionality;
            // might still need these if i return to working it out
            case .Changed:
                return
            
            case .Ended:
                return
            
            default:
                return
        }
    }
    
    func getFlickrResults( pin: Pin )
    {
        FlickrClient.sharedInstance().getResultsForLocation( pin )
        {
            resultsError in
            
            // there was an error with the request
            if resultsError != nil
            {
                dispatch_async( dispatch_get_main_queue() )
                {
                    let alert = UIAlertController(
                        title: "There was an error requesting photo information from Flickr",
                        message: "\( resultsError!.localizedDescription )",
                        preferredStyle: UIAlertControllerStyle.Alert
                    )
                    
                    let alertAction = UIAlertAction(
                        title: "Drop another pin",
                        style: UIAlertActionStyle.Cancel
                        )
                    {
                        action in
                        
                        // remove the Pin; the photo album view controller won't have anything to work with
                        self.mapView.removeAnnotation( pin )
                    }
                    
                    alert.addAction( alertAction )
                    
                    self.presentViewController(
                        alert,
                        animated: true,
                        completion: nil
                    )
                }
            }
            else
            {
                pin.didGetFlickrResults = true
            }
        }
    }
    
    // MARK: MKMapViewDelegate functions
    
    func mapView(
        mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!
    ) -> MKAnnotationView!
    {
        let theAnnotation = annotation as! Pin
        
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? MKPinAnnotationView
        {
            reusedAnnotationView.annotation = theAnnotation
            
            return reusedAnnotationView
        }
        else
        {
            var newAnnotationView = MKPinAnnotationView(
                annotation: theAnnotation,
                reuseIdentifier: "mapPin"
            )
            
            return newAnnotationView
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        didSelectAnnotationView view: MKAnnotationView!
    )
    {
        // get the selected Pin
        let thePin = view.annotation as! Pin
        
        // initiate segue to photo album
        if !inEditMode
        {
            // hang on; the request for Flickr results hasn't finished, yet
            if !thePin.didGetFlickrResults
            {
                mapView.deselectAnnotation( thePin, animated: true )
            }
            else
            {
                selectedPin = thePin
                
                // segue to the photo album
                let photoAlbum = storyboard?.instantiateViewControllerWithIdentifier( "PhotoAlbum" ) as! PhotoAlbumViewController
                photoAlbum.location = thePin
                
                presentViewController(
                    photoAlbum,
                    animated: true,
                    completion: nil
                )
            }
        }
        else
        {
            // editing pins;
            // remove the selected pin from the map, update the model Pin count,
            Pin.removePin()
            mapView.removeAnnotation( thePin )
            
            // update the context
            sharedContext.deleteObject( thePin )
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    // save the map state when it changes
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
