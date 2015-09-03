//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/20/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class FlickrClient: NSObject
{
    // a session to create tasks with
    var session = NSURLSession.sharedSession()
    
    // the location to use when querying Flickr for images
    // var location: CLLocationCoordinate2D!
    
    // the Pin to request images for
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
    
    // queries Flickr for a set of images at the current location;
    // returns an array of URLs for the PhotoAlbumViewController to use to populate the collection view,
    // or a flag that there weren't any results, or the error details, if one occurs
    func getNewPhotoAlbumForLocation(
        pin: Pin,
        completionHandler: ( photoAlbumInfo: [ NSURL ]?, zeroResults: Bool, photoAlbumError: NSError? ) -> Void
    )
    {
        // set the current Pin
        currentPin = pin
        
        // blank the current set of URL info
        currentAlbumPhotoInfo.removeAll( keepCapacity: false )
        
        // make the initial request
        requestResultsForLocation( pin.coordinate )
        {
            success, requestError in
            
            // some kind of error occurred
            if requestError != nil
            {
                completionHandler(
                    photoAlbumInfo: nil,
                    zeroResults: false,
                    photoAlbumError: requestError
                )
            }
            else if success
            {
                // the request was successful, but there weren't any pictures taken at that location
                if self.currentAlbumPhotoInfo.isEmpty
                {
                    completionHandler(
                        photoAlbumInfo: nil,
                        zeroResults: true,
                        photoAlbumError: nil
                    )
                }
                else
                {
                    completionHandler(
                        photoAlbumInfo: self.currentAlbumPhotoInfo,
                        zeroResults: false,
                        photoAlbumError: nil
                    )
                }
            }
        }
    }
    
    func requestResultsForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( success: Bool, requestError: NSError! ) -> Void
    )
    {
        // create the URL to query Flickr with
        let requestURL = createQueryURL( location )
        
        // create the data task
        let requestTask = self.session.dataTaskWithURL( requestURL )
        {
            requestData, requestResponse, requestError in
            
            if requestError != nil
            {
                // pass the error up the chain
                completionHandler(
                    success: false,
                    requestError: requestError
                )
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
                    
                    // if there are results to work with, create a set to return to the PhotoAlbumViewController
                    // if there are no results, the zeroResults flag will get sent, instead
                    if photoArray.count != 0
                    {
                        // take a sub-section of the result set, as configured above;
                        // get next section of the result set if a new album is requested
                        // set the counter to zero if there is only one result, to avoid array index out-of-bounds error
                        // var resultCounter: Int
                        var startPhoto, endPhoto: Int
                        if photoArray.count == 1
                        {
                            startPhoto = 0
                            endPhoto = 0
                        }
                        else
                        {
                            if let nextStart = self.currentPin.nextFirstImage
                            {
                                println( "There were more images..." )
                                startPhoto = nextStart
                                endPhoto = ( photoArray.count > ( nextStart + self.maxImagesToShow ) ) ? ( nextStart + self.maxImagesToShow - 1 ) : self.maxImagesToShow - 1
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
                        self.currentPin.nextFirstImage = endPhoto + 1
                        
                        // create a URL from the info in each dictionary
                        // and append it to the current set
                        for photoInfoDictionary in albumInfos
                        {
                            let imageURL = self.urlForImageInfo( photoInfoDictionary )
                            self.currentAlbumPhotoInfo.append( imageURL )
                        }
                    }
                    
                    // whew, success!!!
                    completionHandler(
                        success: true,
                        requestError: nil
                    )
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
                    
                    completionHandler(
                        success: false,
                        requestError: requestError
                    )
                }
            }
        }
        requestTask.resume()
    }
    
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
}
