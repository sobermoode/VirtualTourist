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
    
    // holder collection
    var currentAlbumPhotoInfo = [ NSURL ]()
    
    // might still need this to cache photo albums returned in the current session,
    // to prevent another query to Flickr for the same set of pictures,
    // because they won't be fetched from Core Data
    var albumForDestinationID = [ Int16 : AnyObject ]()
    
    // max size of the photo album
    // (use to configure the collection view in the PhotoAlbumViewController)
    var maxImagesToShow: Int = 30
    
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
        
        // blank the current set of URL info
        // currentAlbumPhotoInfo.removeAll( keepCapacity: false )
        
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
                        
                        println( "Got \( photoArray.count ) results." )
                        
                        // if there are results to work with, create a set to return to the PhotoAlbumViewController
                        // if there are no results, the zeroResults flag will get sent, instead
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
                                println( "There was 1 result." )
                                startPhoto = 0
                                endPhoto = 0
                                
                                dontSetNextFirstImage = true
                            }
                            else if photoArray.count <= self.maxImagesToShow
                            {
                                println( "There were 30 or less results." )
                                startPhoto = 0
                                endPhoto = photoArray.count - 1
                                
                                dontSetNextFirstImage = true
                            }
                            else
                            {
                                println( "There were 30+ results." )
                                if let nextStart = self.currentPin.nextFirstImage
                                {
                                    println( "There were more images..." )
                                    if ( nextStart + self.maxImagesToShow ) > photoArray.count
                                    {
                                        startPhoto = 0
                                        endPhoto = self.maxImagesToShow - 1
                                    }
                                    else
                                    {
                                        startPhoto = nextStart
                                        endPhoto = ( photoArray.count > ( nextStart + self.maxImagesToShow ) ) ? ( nextStart + self.maxImagesToShow - 1 ) : self.maxImagesToShow - 1
                                    }
                                }
                                else
                                {
                                    println( "Starting over..." )
                                    startPhoto = 0
                                    endPhoto = ( photoArray.count > self.maxImagesToShow ) ? self.maxImagesToShow - 1 : photoArray.count - 1
                                }
                            }
                            
                            // strange casting here;
                            // since taking a sub-section of an array returns a Slice (a pointer into an array, not a new array),
                            // and which is itself a type, i had to cast the Slice into the type i actually want to use
                            // check out https://stackoverflow.com/questions/24073269/what-is-a-slice-in-swift for more
                            let albumInfos = [[ String : AnyObject ]]( photoArray[ startPhoto...endPhoto ] )
                            
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
                            
                            /*
                            // create a URL from the info in each dictionary
                            // and append it to the current set
                            for photoInfoDictionary in albumInfos
                            {
                                let imageURL = self.urlForImageInfo( photoInfoDictionary )
                                self.currentAlbumPhotoInfo.append( imageURL )
                            }
                            */
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
    
    /*
    // creates an NSURL to an actual image from an info dictionary returned from Flickr
    func urlForImageInfo( imageInfo: [ String : AnyObject ] ) -> NSURL!
    {
        let farmID = imageInfo[ "farm" ] as! Int
        let serverID = imageInfo[ "server" ] as! String
        let photoID = imageInfo[ "id" ] as! String
        let secret = imageInfo[ "secret" ] as! String
        
        let imageURLString = "https://farm\( farmID ).staticflickr.com/\( serverID )/\( photoID )_\( secret ).jpg"
        
        return NSURL( string: imageURLString )!
    }
    */
    
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
