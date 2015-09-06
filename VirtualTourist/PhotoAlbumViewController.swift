//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/19/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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
    
    // results returned from Flickr
    var currentAlbumInfo = [ NSURL ]()
    
    // images downloaded during this session
    var localCache = [ Int : UIImage ]()
    
    // a flag for determining whether or not we loaded a photo album from Core Data
    var alreadyHaveImages: Bool = false
    
    lazy var sharedContext: NSManagedObjectContext =
    {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
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
            action: "newCollection:",
            forControlEvents: .TouchUpInside
        )
        
        // set the collection view properties
        photoAlbumCollection.allowsMultipleSelection = true
        photoAlbumCollection.dataSource = self
        photoAlbumCollection.delegate = self
        
        // TODO: remove the label
        // hide the label, unless it is needed
        noImagesLabel.hidden  = true
    }
    
    override func viewWillAppear( animated: Bool )
    {
        // we fetched a photo album from Core Data, or there's a local cache
        if !location.photoAlbum.isEmpty
        {
            alreadyHaveImages = true
            self.photoAlbumCollection.reloadData()
        }
            
        // otherwise, initiate the request for a photo album
        else
        {
            newCollection( nil )
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
    
    func newCollection( sender: UIButton? )
    {
        // initiate the Flickr request for the photo album
        FlickrClient.sharedInstance().getNewPhotoAlbumForLocation( location )
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
                    // save the info to construct URLs to images
                    self.currentAlbumInfo = photoAlbumInfo!
                    
                    // reload the collection view
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.photoAlbumCollection.reloadData()
                    }
                }
            }
        }
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
    
    // the collection view will either use the photo album fetched from Core Data
    // or the results returned from Flickr to populate itself
    func collectionView(
        collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int
    {
        if alreadyHaveImages
        {
            return self.location.photoAlbum.count
        }
        else
        {
            return self.currentAlbumInfo.count
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "photoAlbumCell",
            forIndexPath: indexPath
        ) as! PhotoAlbumCell
        
        // the Pin came with a Photo from Core Data
        if alreadyHaveImages
        {
            let cellImage = location.photoAlbum[ indexPath.item ].image
            cell.photoImageView.image = cellImage
        }
        
        // no Core Data image, but check the local cache for an already-downloaded image
        else if let cellImage = localCache[ indexPath.item ]
        {
            cell.photoImageView.image = cellImage
        }
            
        // otherwise, we have to download images from Flickr
        else
        {
            // get the URL for the image
            let imageURL = self.currentAlbumInfo[ indexPath.item ]
            
            dispatch_async( dispatch_get_main_queue() )
            {
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
                        // create the Photo object with the downloaded data
                        let cellPhoto = Photo(
                            pin: self.location,
                            imageData: imageData!,
                            context: self.sharedContext
                        )
                        
                        // update the local cache
                        self.localCache.updateValue( UIImage( data: imageData! )!, forKey: indexPath.item )
                        
                        // save the context
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        // set the cell
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            cell.photoImageView.image = UIImage( data: imageData! )
                        }
                    }
                }
            }
        }
        
        return cell
    }
}