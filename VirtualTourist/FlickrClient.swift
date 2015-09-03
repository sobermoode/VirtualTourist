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
    var location: CLLocationCoordinate2D!
    
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
    // 
    func getNewPhotoAlbumForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( success: Bool, zeroResults: Bool, photoAlbumError: NSError? ) -> Void
    )
    {
        // currentAlbumImageData.removeAll( keepCapacity: false )
        currentAlbumPhotoInfo.removeAll( keepCapacity: false )
        // currentAlbumImages.removeAll( keepCapacity: false )
        
        requestResultsForLocation( location )
        {
            success, requestError in
            
            if requestError != nil
            {
                completionHandler(
                    success: false,
                    zeroResults: false,
                    photoAlbumError: requestError
                )
            }
            else if success
            {
                if self.currentAlbumPhotoInfo.isEmpty
                {
                    completionHandler(
                        success: true,
                        zeroResults: true,
                        photoAlbumError: nil
                    )
                }
                else
                {
                    completionHandler(
                        success: true,
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
        println( "requestResultsForDestination..." )
        
        // var photoInfo = [ [ String : AnyObject ] ]()
        // var imageResults: [ UIImage ]?
        
        let requestURL = createQueryURL( location )
        
        let requestTask = self.session.dataTaskWithURL( requestURL )
        {
            requestData, requestResponse, requestError in
            
            if requestError != nil
            {
                completionHandler(
                    success: false,
                    requestError: requestError
                )
            }
            else
            {
                var jsonificationError: NSErrorPointer = nil
                if let requestResults = NSJSONSerialization.JSONObjectWithData(
                    requestData,
                    options: nil,
                    error: jsonificationError
                ) as? [ String : AnyObject ]
                {
                    // println( "Parsing results from Flickr..." )
                    // println( "requestResults: \( requestResults )" )
                    let photos = requestResults[ "photos" ] as! [ String : AnyObject ]
                    let photoArray = photos[ "photo" ] as! [[ String : AnyObject ]]
                    
                    // var photoResults = [[ String : AnyObject ]?]()
                    println( "photoArray.count: \( photoArray.count )" )
                    if photoArray.count != 0
                    {
                        var resultCounter: Int
                        if photoArray.count == 1
                        {
                            resultCounter = 0
                        }
                        else
                        {
                            resultCounter = ( photoArray.count > self.maxImagesToShow ) ? self.maxImagesToShow - 1 : photoArray.count - 1
                            println( "resultCounter: \( resultCounter )" )
                        }
                        
                        // let photoRange = NSMakeRange(0, resultCounter)
                        // let photoIndices = NSIndexSet(indexesInRange: photoRange)
                        
                        // strange casting here;
                        // since taking a sub-section of an array returns a Slice (a pointer into an array, not a new array),
                        // and which is itself a type, i had to cast the Slice into the type i actually want to use
                        // check out https://stackoverflow.com/questions/24073269/what-is-a-slice-in-swift for more
                        let albumInfos = [ [ String : AnyObject ] ]( photoArray[ 0...resultCounter ] )
                        
                        for photoInfoDictionary in albumInfos
                        {
                            let imageURL = self.urlForImageInfo( photoInfoDictionary )
                            self.currentAlbumPhotoInfo.append( imageURL )
                            // let imageData = NSData( contentsOfURL: imageURL )!
                            // self.currentAlbumImageData.append( imageData )
                        }
                    }
                    
                    completionHandler(
                        success: true,
                        requestError: nil
                    )
                }
                else
                {
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
    
    func urlForImageInfo( imageInfo: [ String : AnyObject ] ) -> NSURL!
    {
        let farmID = imageInfo[ "farm" ] as! Int
        let serverID = imageInfo[ "server" ] as! String
        let photoID = imageInfo[ "id" ] as! String
        let secret = imageInfo[ "secret" ] as! String
        
        let imageURLString = "https://farm\( farmID ).staticflickr.com/\( serverID )/\( photoID )_\( secret ).jpg"
        
        return NSURL( string: imageURLString )!
    }
    
    func taskForImage(
        imageInfo: [ String : AnyObject ],
        completionHandler: ( imageData: NSData?, imageError: NSError? ) -> Void
    )
    {
        let farmID = imageInfo[ "farm" ] as! Int
        let serverID = imageInfo[ "server" ] as! String
        let photoID = imageInfo[ "id" ] as! String
        let secret = imageInfo[ "secret" ] as! String
        
        let imageURLString = "https://farm\( farmID ).staticflickr.com/\( serverID )/\( photoID )_\( secret ).jpg"
        let imageURL = NSURL( string: imageURLString )!
        
        // var imageTask = NSURLSessionDataTask()
        let imageTask = self.session.dataTaskWithURL( imageURL )
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
    
//    func getPhotoResults() -> [[ String : AnyObject ]]
//    {
//        return albumPhotos
//    }
}
