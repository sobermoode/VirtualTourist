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
    var location: Pin!
    
    // collections for the current photo album
    var currentAlbumInfo = [ NSURL ]()
    // var currentAlbumImages = [ UIImage? ]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
        
        // TODO: remove the label
        // hide the label, unless it is needed
        noImagesLabel.hidden  = true
        
        // don't make a request for a new album if we're revisiting an album
        if location.photoAlbum != nil
        {
            // we already have an album, so reload the collection view
            dispatch_async( dispatch_get_main_queue() )
            {
                self.photoAlbumCollection.reloadData()
            }
        }
        else
        {
            // initiate the Flickr request for the photo album
            FlickrClient.sharedInstance().getNewPhotoAlbumForLocation( location.coordinate )
            {
                photoAlbumInfo, zeroResults, photoAlbumError in
                
                // there was an error somewhere along the way
                if photoAlbumError != nil
                {
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.photoAlbumCollection.hidden = true
                        
                        let alert = UIAlertController(
                            title: "There was an error requesting the photos from Flickr:",
                            message: "\( photoAlbumError )",
                            preferredStyle: UIAlertControllerStyle.Alert
                        )
                        
                        let alertAction = UIAlertAction(
                            title: "Keep Traveling",
                            style: UIAlertActionStyle.Cancel
                        )
                        {
                            action in
                            
                            let travelMap = self.presentingViewController as! TravelMapViewController
                            travelMap.returningFromPhotoAlbum = true
                            
                            self.dismissViewControllerAnimated( true, completion: nil )
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
                    // nobody took any pictures there
                    if zeroResults
                    {
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            self.photoAlbumCollection.hidden = true
                            
                            let alert = UIAlertController(
                                title: "😓   😓   😓",
                                message: "No one took any pictures at that location.",
                                preferredStyle: UIAlertControllerStyle.Alert
                            )
                            
                            let alertAction = UIAlertAction(
                                title: "Keep Traveling",
                                style: UIAlertActionStyle.Cancel
                            )
                            {
                                action in
                                
                                let travelMap = self.presentingViewController as! TravelMapViewController
                                travelMap.returningFromPhotoAlbum = true
                                
                                self.dismissViewControllerAnimated( true, completion: nil )
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
                        // we've got a photo album!
                        // save the info to construct URLs to images and populate the array of current images to nil
                        self.currentAlbumInfo = photoAlbumInfo!
                        
                        // initialize the Pin's photo album
                        self.location.photoAlbum = [ Photo? ](
                            count: photoAlbumInfo!.count,
                            repeatedValue: nil
                        )
                        
                        // reload the collection view
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            self.photoAlbumCollection.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Set-up functions
    
    // create the nav bar
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
        // center the map on the location where the user dropped the pin and zoom in
        mapView.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
        
        // drop a pin in the same location
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        mapView.addAnnotation( pin )
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
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "photoAlbumPin" ) as? MKPinAnnotationView
        {
            reusedAnnotationView.annotation = annotation
            
            return reusedAnnotationView
        }
        else
        {
            var newAnnotationView = MKPinAnnotationView(
                annotation: annotation,
                reuseIdentifier: "photoAlbumPin"
            )
            
            return newAnnotationView
        }
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
        // make sure we've got a photo album to populate the collection view with
        if let theCount = self.location.photoAlbum?.count
        {
            return theCount
        }
        else
        {
            return 0
        }
    }
    
    // NOTE:
    // logic inspired by http://natashatherobot.com/ios-how-to-download-images-asynchronously-make-uitableview-scroll-fast/
    func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath
    ) -> UICollectionViewCell
    {
        // dequeue a cell
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "photoAlbumCell",
            forIndexPath: indexPath
        ) as? PhotoAlbumCell
        {
            // use the already-downloaded image, if it exists
            if let cellImage = location.photoAlbum![ indexPath.item ]
            {
                dispatch_async( dispatch_get_main_queue() )
                {
                    cell.photoImageView.image = cellImage.image
                }
                
                return cell
            }
            else
            {
                // download the image for the cell, if necessary
                dispatch_async( dispatch_get_main_queue() )
                {
                    // get the URL for the cell
                    let imageURL = self.currentAlbumInfo[ indexPath.item ]
                    
                    // start the image task
                    FlickrClient.sharedInstance().taskForImage( imageURL )
                    {
                        imageData, imageError in
                        
                        // an error happened
                        if imageError != nil
                        {
                            dispatch_async( dispatch_get_main_queue() )
                            {
                                let alert = UIAlertController(
                                    title: "There was an error getting the image for cell \( indexPath.item ):",
                                    message: "\( imageError )",
                                    preferredStyle: UIAlertControllerStyle.Alert
                                )
                                
                                let alertAction = UIAlertAction(
                                    title: "😓   😓   😓",
                                    style: UIAlertActionStyle.Cancel
                                )
                                {
                                    action in
                                    
                                    return
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
                            // create the cell image with the downloaded data
                            // let cellImage = UIImage( data: imageData! )
                            let cellPhoto = Photo(
                                pin: self.location,
                                imageData: imageData!
                            )
                            
                            // set the cell and save the image to the local cache
                            dispatch_async( dispatch_get_main_queue() )
                            {
                                cell.photoImageView.image = cellPhoto.image
                                self.location.photoAlbum![ indexPath.item ] = cellPhoto
                            }
                        }
                    }
                }
                
                return cell
            }
        }
        else
        {
            return UICollectionViewCell( frame: CGRect( x: 0, y: 0, width: 125, height: 108 ) )
        }
    }
}
