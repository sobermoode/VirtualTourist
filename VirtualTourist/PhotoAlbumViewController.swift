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
    // var currentAlbumInfo = [ NSURL ]()
    
    // a flag for determining whether or not we loaded a photo album from Core Data
    // var alreadyHaveImages: Bool = false
    
    lazy var sharedContext: NSManagedObjectContext =
    {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    // for use with toggling the New Collection/Remove Items button
    var defaultColor: UIColor!
    enum NewCollectionButtonState
    {
        case NewCollection
        case RemoveSelected
    }
    var buttonIsToggled: Bool = false
    
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
        
        // the default UIButton text color is not a UIColor preset; this is one way to get it
        defaultColor = self.view.tintColor
        
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
        // the user deleted all the photos from the collection but didn't request a new collection;
        // upon returning to the photo album, get a new collection automatically
        if location.needsNewPhotoAlbum
        {
            location.needsNewPhotoAlbum = false
            
            newCollection( nil )
        }
        
        // there were zero photos taken at the location
        else if location.photoAlbum.isEmpty
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
    }
    
    /*
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
    */
    
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
    
    // request a new photo album from Flickr
    func newCollection( sender: UIButton? )
    {
        println( "newCollection..." )
        FlickrClient.sharedInstance().getResultsForLocation( location )
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
                        title: "Try again",
                        style: UIAlertActionStyle.Cancel
                    )
                    {
                        action in
                        
                        // TODO: implement this error
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
                
            // the request was successful, so reload the collection view
            else
            {
                dispatch_async( dispatch_get_main_queue() )
                {
                    self.photoAlbumCollection.reloadData()
                }
            }
        }
    }
    
    // remove the selected items from the collection view
    func removeItems( sender: UIButton )
    {
        // get the selected index paths
        let selectedIndexPaths = photoAlbumCollection.indexPathsForSelectedItems() as! [ NSIndexPath ]
        
        // delete the items from the photo album and Core Data
        for indexPath in selectedIndexPaths
        {
            let photo = location.photoAlbum[ indexPath.item ]
            sharedContext.deleteObject( photo )
            println( "The photo album has \( location.photoAlbum.count ) images." )
        }
        
        // save the context
        CoreDataStackManager.sharedInstance().saveContext()
        println( "The photo album has \( location.photoAlbum.count ) images." )
        
        // delete the items from the collection view
        photoAlbumCollection.deleteItemsAtIndexPaths( selectedIndexPaths )
        
        if location.photoAlbum.isEmpty
        {
            location.needsNewPhotoAlbum = true
        }
        
        // return the button to its default state
        toggleButton( NewCollectionButtonState.NewCollection )
    }
    
    // toggle the text and functionality of the button
    func toggleButton( state: NewCollectionButtonState )
    {
        switch state
        {
            // set the button to retrieve a new photo album
            case .NewCollection:
                newCollectionButton.setTitle( "New Collection", forState: UIControlState.Normal )
                newCollectionButton.setTitleColor( defaultColor, forState: UIControlState.Normal )
                newCollectionButton.removeTarget(
                    self,
                    action: "removeItems:",
                    forControlEvents: .TouchUpInside
                )
                newCollectionButton.addTarget(
                    self,
                    action: "newCollection:",
                    forControlEvents: .TouchUpInside
                )
            
                buttonIsToggled = false
            
            // set the button to remove items from the collection view
            case .RemoveSelected:
                newCollectionButton.setTitle( "Remove Selected Items", forState: UIControlState.Normal )
                newCollectionButton.setTitleColor( UIColor.redColor(), forState: UIControlState.Normal )
                newCollectionButton.removeTarget(
                    self,
                    action: "newCollection:",
                    forControlEvents: .TouchUpInside
                )
                newCollectionButton.addTarget(
                    self,
                    action: "removeItems:",
                    forControlEvents: .TouchUpInside
                )
            
                buttonIsToggled = true
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
        return location.photoAlbum.count
        /*
        if alreadyHaveImages
        {
            return self.location.photoAlbum.count
        }
        else
        {
            return self.currentAlbumInfo.count
        }
        */
    }
    
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
        
        // set the placeholder image
        cell.photoImageView.image = UIImage( named: "placeholder" )
        
        // set cell selection state
        cell.alpha = ( cell.selected ) ? 0.35 : 1.0
        
        // get the Photo for the cell
        let cellPhoto = location.photoAlbum[ indexPath.item ]
        
        // get the image saved to Core Data
        if let cellImage = cellPhoto.image
        {
            println( "Using Core Data image..." )
            cell.activityIndicator.stopAnimating()
            cell.photoImageView.image = cellImage
        }
        
        // check to see if the image has been written to disk for reuse
        else if let filePath = cellPhoto.filePath
        {
            println( "Getting a cached image..." )
            dispatch_async( dispatch_get_main_queue() )
            {
                FlickrClient.sharedInstance().taskForImageData( filePath )
                {
                    imageData, taskError in
                    
                    // something happened
                    if taskError != nil
                    {
                        // not going to pop up an alert here;
                        // we'll just use the placeholder image until the cached image can be retrieved
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            cell.photoImageView.image = UIImage( named: "placeholder" )
                        }
                    }
                    else if let cachedImageData = imageData
                    {
                        // use the cached image
                        let cachedImage = UIImage( data: cachedImageData )
                        
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            cell.activityIndicator.stopAnimating()
                            cell.photoImageView.image = cachedImage
                        }
                    }
                }
            }
        }
        
        // otherwise, download the image from Flickr
        else
        {
            println( "Downloading an image..." )
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            
            let imageURL = cellPhoto.imageURL!
            FlickrClient.sharedInstance().taskForImage( imageURL )
            {
                imageData, imageError in
                
                // an error happened
                if imageError != nil
                {
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        let alert = UIAlertController(
                            title: "There was an error retrieving one of the photos.",
                            message: "\( imageError!.localizedDescription )",
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
                    // write the image to the documents directory for caching
                    cellPhoto.createImageFileURL()
                    
                    imageData!.writeToURL(
                        cellPhoto.filePath!,
                        options: nil,
                        error: nil
                    )
                    
                    // save the image to fetch from Core Data
                    cellPhoto.image = UIImage( data: imageData! )!
                    
                    // save the context
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    // set the cell
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        cell.activityIndicator.hidden = true
                        cell.activityIndicator.stopAnimating()
                        cell.photoImageView.image = UIImage( data: imageData! )
                    }
                }
            }
        }
        
        return cell
        
        /*
        // the Pin came with a Photo from Core Data
        if alreadyHaveImages
        {
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()
            
            let cellImage = location.photoAlbum[ indexPath.item ].image
            cell.photoImageView.image = cellImage
            
            return cell
        }
        
        // if no images from Core Data, look for a cached image
        // get a Photo at a valid index
        if !( indexPath.item >= location.photoAlbum.count )
        {
            if let cellPhoto = location.photoAlbum[ indexPath.item ]
            {
                let filePath = cellPhoto.filePath!
                
                // return image data from the documents directory
                FlickrClient.sharedInstance().taskForImageData( filePath )
                {
                    imageData, taskError in
                    
                    // something happened
                    if taskError != nil
                    {
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            let alert = UIAlertController(
                                title: "There was an error getting a cached image:",
                                message: "\( taskError!.localizedDescription )",
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
                        // put the image in the cell
                        let cellImage = UIImage( data: imageData! )
                        
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            cell.photoImageView.image = cellImage
                        }
                    }
                }
                
                return cell
            }
            
            return cell
        }
        
        // otherwise, we have to download images from Flickr
        else
        {
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            cell.photoImageView.image = UIImage( named: "placeholder" )
            
            // get the URL for the image
            let imageURL = self.currentAlbumInfo[ indexPath.item ]
            
            dispatch_async( dispatch_get_main_queue() )
            {
                // start the image task
                let imageTask = FlickrClient.sharedInstance().taskForImage( imageURL )
                {
                    imageData, imageError in
                    
                    // an error happened
                    if imageError != nil
                    {
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            let alert = UIAlertController(
                                title: "Couldn't retrieve one of the photos.",
                                message: "\( imageError!.localizedDescription )",
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
                        
                        // write the image to the documents directory for caching
                        imageData!.writeToURL(
                            cellPhoto.filePath!,
                            options: nil,
                            error: nil
                        )
                        
                        // save the context
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        // set the cell
                        dispatch_async( dispatch_get_main_queue() )
                        {
                            cell.activityIndicator.hidden = true
                            cell.activityIndicator.stopAnimating()
                            cell.photoImageView.image = UIImage( data: imageData! )
                        }
                    }
                }
            }
            
            return cell
        }
        */
    }
    
    func collectionView(
        collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath
    )
    {
        let cell = collectionView.cellForItemAtIndexPath( indexPath ) as! PhotoAlbumCell
        
        // toggle button if necessary
        if collectionView.indexPathsForSelectedItems().count > 0 && !buttonIsToggled
        {
            toggleButton( NewCollectionButtonState.RemoveSelected )
        }
        
        // set cell selected state
        cell.selected = true
        cell.alpha = 0.35
    }
    
    func collectionView(
        collectionView: UICollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath
    )
    {
        let cell = collectionView.cellForItemAtIndexPath( indexPath ) as! PhotoAlbumCell
        
        // set cell deselected state
        cell.selected = false
        cell.alpha = 1.0
        
        // toggle button if necessary
        if collectionView.indexPathsForSelectedItems().count == 0
        {
            toggleButton( NewCollectionButtonState.NewCollection )
        }
    }
}