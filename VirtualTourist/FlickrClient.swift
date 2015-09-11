//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/20/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FlickrClient: NSObject
{
    // a reference to the context
    lazy var sharedContext: NSManagedObjectContext =
    {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    // a session to create tasks with
    var session = NSURLSession.sharedSession()
    
    // the location to request images for
    var currentPin: Pin!
    
    // max size of the photo album
    // (use to configure the collection view in the PhotoAlbumViewController)
    var maxImagesToShow: Int = 30
    
    // save the (up to 250) results from the Flickr request for subsequent new collection requests
    var currentResults = [[ String : AnyObject ]]()
    
    // NOTE:
    // inspired by the Movie class from the FavoriteActors project
    struct QueryParameters
    {
        static let baseURL = "https://api.flickr.com/services/rest/?"
        static let method = "flickr.photos.search"
        static let apiKey = "71549104e5500eb7d194d040cc55ea10"
        static let format = "json"
        static let nojsoncallback = 1
    }
    
    // NOTE:
    // modeled after the MovieDB client class from the FavoriteActors project
    class func sharedInstance() -> FlickrClient
    {
        struct Singleton
        {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    // create the query URL
    func createQueryURL( location: CLLocationCoordinate2D ) -> NSURL!
    {
        let queryString = "\( QueryParameters.baseURL )method=\( QueryParameters.method )&api_key=\( QueryParameters.apiKey )&lat=\( location.latitude )&lon=\( location.longitude )&format=\( QueryParameters.format )&nojsoncallback=\( QueryParameters.nojsoncallback )"
        
        return NSURL( string: queryString )!
    }
    
    // queries Flickr for the information required to construct URLs to the images for the photo album
    func getResultsForLocation(
        pin: Pin,
        completionHandler: ( resultsError: NSError? ) -> Void
    )
    {
        // set the current Pin
        currentPin = pin
        
        // delete all current Photo objects and save the context
        if !pin.photoAlbum.isEmpty
        {
            for photo in pin.photoAlbum
            {
                sharedContext.deleteObject( photo )
            }
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        // make the initial request
        requestResultsForLocation( pin.coordinate )
        {
            requestError in
            
            // some kind of error occurred
            if requestError != nil
            {
                completionHandler( resultsError: requestError )
            }
            else
            {
                completionHandler( resultsError: nil )
            }
        }
    }
    
    func requestResultsForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( requestError: NSError! ) -> Void
    )
    {
        // create the URL to query Flickr with
        let requestURL = createQueryURL( location )
        
        dispatch_async( dispatch_get_main_queue() )
        {
            // create the data task
            let requestTask = self.session.dataTaskWithURL( requestURL )
            {
                requestData, requestResponse, requestError in
                
                if requestError != nil
                {
                    // pass the error up the chain
                    completionHandler( requestError: requestError )
                }
                else
                {
                    // parse the results
                    var jsonificationError: NSErrorPointer = nil
                    if let requestResults = NSJSONSerialization.JSONObjectWithData(
                        requestData,
                        options: nil,
                        error: jsonificationError
                    ) as? [ String : AnyObject ]
                    {
                        // get at the array of dictionaries that contain the info for constructing URLs to images
                        let photos = requestResults[ "photos" ] as! [ String : AnyObject ]
                        let photoArray = photos[ "photo" ] as! [[ String : AnyObject ]]
                        
                        self.currentResults = photoArray
                        
                        // if there are results to work with, populate the Pin's photo album with Photo objects that contain the relevant URL info
                        if photoArray.count != 0
                        {
                            // take a sub-section of the result set, as configured above;
                            // get next section of the result set if a new album is requested (in current session; see below)
                            // NOTE: this code is imperfect; if the result set is less than ( self.maxImagesToShow * 2 ),
                            // requesting a new collection will yield the exact same set of images. otherwise, it will
                            // get a new full album, until the next set contains less than ( self.maxImagesToShow * 2 ).
                            // ALSO: if you drop and pin, look at the photo album, quit the app, look at the same photo album,
                            // and then request a new collection, you'll get the exact same results. a new request always
                            // returns the first set of results, so the new collection will be the same as the old collection
                            // (since both requests were for the first set of results). you could end up seeing the same collection
                            // many times in a row, and think something is faulty, when in fact, that's how its "supposed" to work.
                            // set the counter to zero if there is only one result, to avoid array index out-of-bounds error
                            var startPhoto, endPhoto: Int
                            var dontSetNextFirstImage: Bool = false
                            if photoArray.count == 1
                            {
                                startPhoto = 0
                                endPhoto = 0
                                
                                dontSetNextFirstImage = true
                            }
                            else if photoArray.count <= self.maxImagesToShow
                            {
                                startPhoto = 0
                                endPhoto = photoArray.count - 1
                                
                                dontSetNextFirstImage = true
                            }
                            else
                            {
                                if let nextStart = self.currentPin.nextFirstImage
                                {
                                    if ( nextStart + self.maxImagesToShow ) > photoArray.count
                                    {
                                        startPhoto = 0
                                        endPhoto = self.maxImagesToShow - 1
                                        self.currentPin.nextFirstImage = nil
                                    }
                                    else
                                    {
                                        startPhoto = nextStart
                                        endPhoto = ( photoArray.count > ( nextStart + self.maxImagesToShow ) ) ? ( nextStart + self.maxImagesToShow - 1 ) : self.maxImagesToShow - 1
                                        self.currentPin.nextFirstImage = endPhoto + 1
                                    }
                                }
                                else
                                {
                                    startPhoto = 0
                                    endPhoto = ( photoArray.count > self.maxImagesToShow ) ? self.maxImagesToShow - 1 : photoArray.count - 1
                                    self.currentPin.nextFirstImage = endPhoto + 1
                                }
                            }
                            
                            // strange casting here;
                            // since taking a sub-section of an array returns a Slice (a pointer into an array, not a new array),
                            // and which is itself a type, i had to cast the Slice into the type i actually want to use
                            // check out https://stackoverflow.com/questions/24073269/what-is-a-slice-in-swift for more
                            let albumInfos = [[ String : AnyObject ]]( self.currentResults[ startPhoto...endPhoto ] )
                            
                            // update the album counter
                            self.currentPin.nextFirstImage = ( dontSetNextFirstImage ) ? nil : endPhoto + 1
                            
                            // create a Photo with each information dictionary
                            for photoInfoDictionary in albumInfos
                            {
                                let newPhoto = Photo(
                                    pin: self.currentPin,
                                    imageInfo: photoInfoDictionary,
                                    context: self.sharedContext
                                )
                            }
                        }
                        
                        // whew, success!!!
                        completionHandler( requestError: nil )
                    }
                    else
                    {
                        // if the JSON-ification of the results from Flickr failed, somehow,
                        // create an error to send back up the chain
                        let errorDictionary = [ NSLocalizedDescriptionKey : "There was an error with the request results from Flickr." ]
                        let requestError = NSError(
                            domain: "Virtual Tourist",
                            code: 2112,
                            userInfo: errorDictionary
                        )
                        
                        completionHandler( requestError: requestError )
                    }
                }
            }
            requestTask.resume()
        }
    }
    
    // task for downloading an image from Flickr
    func taskForImage(
        imageURL: NSURL,
        completionHandler: ( imageData: NSData?, imageError: NSError? ) -> Void
    )
    {
        let imageTask = session.dataTaskWithURL( imageURL )
        {
            imageData, imageResponse, imageError in
            
            if imageError != nil
            {
                completionHandler(
                    imageData: nil,
                    imageError: imageError
                )
            }
            else
            {
                completionHandler(
                    imageData: imageData,
                    imageError: nil
                )
            }
        }
        imageTask.resume()
    }

    // task for returning image data saved to the device
    func taskForImageData(
        filePath: NSURL,
        completionHandler: ( imageData: NSData?, taskError: NSError? ) -> Void
    )
    {
        let imageDataTask = session.dataTaskWithURL( filePath )
        {
            imageData, taskResponse, taskError in
            
            if taskError != nil
            {
                completionHandler(
                    imageData: nil,
                    taskError: taskError
                )
            }
            else
            {
                completionHandler(
                    imageData: imageData,
                    taskError: nil
                )
            }
        }
        imageDataTask.resume()
    }
}
