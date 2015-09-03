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
//    var location = CLLocationCoordinate2D(
//        latitude: 33.862237,
//        longitude: -118.399519
//    )
    // var location: CLLocationCoordinate2D!
    
    var photoResults = [[ String : AnyObject ]?]()
    
    var currentAlbum = [ UIImage? ]()
    
    var photoAlbum: [ UIImage ]?
    
    var firstTime: Bool = false
    
    var currentAlbumImageData = [ NSData ]()
    var currentAlbumImages = [ UIImage? ]()
    
    override func viewDidLoad()
    {
        // println( "PhotoAlbum viewDidLoad: There are \( Pin.getCurrentPinNumber() ) pins." )
        
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
        // photoAlbumCollection.registerClass(PhotoAlbumCell.self, forCellWithReuseIdentifier: "photoAlbumCell")
        
        // hide the label, unless it is needed
        noImagesLabel.hidden  = true
        
        FlickrClient.sharedInstance().getNewPhotoAlbumForLocation( location.coordinate )
        {
            photoAlbumInfo, zeroResults, photoAlbumError in
            
            if photoAlbumError != nil
            {
                // TODO: turn this into an alert
                println( "There was a problem requesting the photos from Flickr: \( photoAlbumError )" )
            }
            else
            {
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
                    self.currentAlbumImages = [ UIImage? ](
                        count: photoAlbumInfo!.count,
                        repeatedValue: nil
                    )
                    
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.photoAlbumCollection.reloadData()
                    }
                }
            }
        }
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
            center: location.coordinate,
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
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? MKPinAnnotationView
        {
            println( "Reusing an annotation view..." )
            let reusedAnnotation = annotation as! Pin
            reusedAnnotationView.annotation = reusedAnnotation
            // reusedAnnotationView.pin = TravelMapAnnotationView.pinToReuse
            
            return reusedAnnotationView
        }
        else
        {
            println( "Creating new annotation view..." )
            let newAnnotation = annotation as! Pin
            var newAnnotationView = MKPinAnnotationView(
                annotation: annotation,
                reuseIdentifier: "mapPin"
            )
            
            // newAnnotationView.tag = ++totalPins
            
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
        // return FlickrClient.sharedInstance().currentAlbumPhotoInfo.count
        return self.currentAlbumImages.count
    }
    
    // NOTE:
    // logic inspired by http://natashatherobot.com/ios-how-to-download-images-asynchronously-make-uitableview-scroll-fast/
    func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath
    ) -> UICollectionViewCell
    {
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "photoAlbumCell",
            forIndexPath: indexPath
        ) as? PhotoAlbumCell
        {
            if let cellImage = currentAlbumImages[ indexPath.item ]
            {
                cell.photoImageView.image = cellImage
                
                return cell
            }
            else
            {
                dispatch_async( dispatch_get_main_queue() )
                {
                    let imageURL = FlickrClient.sharedInstance().currentAlbumPhotoInfo[ indexPath.item ]
                    
                    let imageTask = NSURLSession.sharedSession().dataTaskWithURL( imageURL )
                    {
                        imageData, imageResponse, imageError in
                        
                        let cellImage = UIImage( data: imageData )
                        
                        cell.photoImageView.image = cellImage
                        self.currentAlbumImages[ indexPath.item ] = cellImage
                    }
                    imageTask.resume()
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
