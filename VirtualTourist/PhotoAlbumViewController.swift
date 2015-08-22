//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/19/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController,
    MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate
{
    // outlets
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var photoAlbumCollection: UICollectionView!
    
    // the location selected from the travel map
    // var location: Pin!
//    var location = CLLocationCoordinate2D(
//        latitude: 33.862237,
//        longitude: -118.399519
//    )
    var location: CLLocationCoordinate2D!
    
    var photoResults = [[ String : AnyObject ]?]()
    
    var currentAlbum = [ UIImage? ]( count: 30, repeatedValue: nil )
    
    override func viewDidLoad()
    {
        println( "PhotoAlbum viewDidLoad: There are \( Pin.getCurrentPinNumber() ) pins." )
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // println( "location.pinNumber: \( location.pinNumber )" )
        
        // set up views
        setUpNavBar()
        setUpMap()
        
        // add action to the button
        newCollectionButton.addTarget(
            self,
            action: "newCollection",
            forControlEvents: .TouchUpInside
        )
        
        // set the collection view properties
        photoAlbumCollection.allowsMultipleSelection = true
        photoAlbumCollection.dataSource = self
        photoAlbumCollection.delegate = self
        
        // hide the label, unless it is needed
        noImagesLabel.hidden  = true
        
        FlickrClient.sharedInstance().requestResultsForLocation( location )
        {
            photoResults, requestError in
            
            if requestError != nil
            {
                println( "There was a problem requesting the photos from Flickr: \( requestError )" )
            }
            else
            {
                self.photoResults = photoResults
                
                dispatch_async( dispatch_get_main_queue() )
                {
                    self.photoAlbumCollection.reloadData()
                }
            }
        }
        
        // println( FlickrClient.sharedInstance().getPhotoResults() )
    }
    
    // MARK: Set-up functions
    
    func setUpNavBar()
    {
        var navItem = UINavigationItem( title: "Photo Album" )
        
        let backButton = UIBarButtonItem(
            title: "Back to Map",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: "backToMap:"
        )
        
        navItem.leftBarButtonItem = backButton
        
        navBar.items = [ navItem ]
    }
    
    func setUpMap()
    {
//        let defaultRegion = MKCoordinateRegion(
//            center: location,
//            span: MKCoordinateSpan(
//                latitudeDelta: 3.0,
//                longitudeDelta: 3.0
//            )
//        )
//        
//        mapView.region = defaultRegion
        
        mapView.region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
        
//        let locationAnnotation = MKPointAnnotation()
//        locationAnnotation.coordinate = location
//        
//         mapView.addAnnotation( Pin.getAnnotationForPinNumber( location.pinNumber ) )
    }
    
    // MARK: Button functions
    
    // return to the map
    func backToMap( sender: UIBarButtonItem )
    {
        let travelMap = self.presentingViewController as! TravelMapViewController
        travelMap.returningFromPhotoAlbum = true
        
        dismissViewControllerAnimated(
            true,
            completion: nil
        )
    }
    
    // MARK: MKMapViewDelegate functions
    
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
    
    // MARK: UICollectionViewDataSource, UICollectionViewDelegate functions
    
    func numberOfSectionsInCollectionView( collectionView: UICollectionView ) -> Int
    {
        return 1
    }
    
    func collectionView(
        collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int
    {
        return 30
    }
    
    func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath
    ) -> UICollectionViewCell
    {
//        if self.photoResults != nil
//        {
//            println( "Getting URL \( self.photoResults![ indexPath.item ] )" )
//        }

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "photoAlbumCell",
            forIndexPath: indexPath
        ) as! PhotoAlbumCell
        
        // set the cell dimensions
        cell.frame.size.width = ( collectionView.collectionViewLayout.collectionViewContentSize().width / 3 ) - 10
        cell.frame.size.height = cell.frame.size.width
        
        // NOTE:
        // trick taken from https://stackoverflow.com/questions/2638120/can-i-change-the-size-of-uiactivityindicator
        cell.activityIndicator.transform = CGAffineTransformMakeScale( 1.5, 1.5 )
        
        // var imageTask = NSURLSessionDataTask
        if photoResults.count != 0
        {
            if let imageInfo = photoResults[ indexPath.item ]
            {
                if cell.imageTask != nil
                {
                    if let cellImage = self.currentAlbum[ indexPath.item ]
                    {
                        cell.photoImageView.image = self.currentAlbum[ indexPath.item ]
                    }
                    
                    return cell
                }
                else
                {
                    let imageTask = FlickrClient.sharedInstance().taskForImage( imageInfo )
                    {
                        imageData, imageError in
                        
                        if imageError != nil
                        {
                            println( "There was an error retrieving the image from Flickr: \( imageError )" )
                        }
                        else
                        {
                            cell.photoImageView.image = UIImage( data: imageData! )
                            self.currentAlbum[ indexPath.item ] = UIImage( data: imageData! )!
                        }
                    }
                    
                    cell.imageTask = imageTask
                    
                    return cell
                }
            }
        }
        
        return cell
    }
}
