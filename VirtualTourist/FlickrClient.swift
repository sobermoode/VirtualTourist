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
    // var destination: Pin!
    
    // holder collections
    var currentAlbumPhotoInfo = [[ String : AnyObject ]]()
    var currentAlbumImageData = [ NSData ]()
    // var albumImages: [ UIImage? ]?
    var currentAlbumImages = [ UIImage ]()
    
    // var currentDestinationID: Int16!
    var albumForDestinationID = [ Int16 : AnyObject ]()
    
    // max size of the photo album
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
    
    func getNewPhotoAlbumForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( success: Bool, zeroResults: Bool, photoAlbumError: NSError? ) -> Void
    )
    {
        currentAlbumImageData.removeAll(keepCapacity: false)
        currentAlbumImages.removeAll(keepCapacity: false)
        
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
                if self.currentAlbumPhotoInfo.count == 0 || self.currentAlbumImageData.count == 0
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
                        self.currentAlbumPhotoInfo = [ [ String : AnyObject ] ]( photoArray[ 0...resultCounter ] )
                        
                        for photoInfoDictionary in photoArray
                        {
                            let imageURL = self.urlForImageInfo( photoInfoDictionary )
                            let imageData = NSData( contentsOfURL: imageURL )!
                            self.currentAlbumImageData.append( imageData )
                        }
                        
                        completionHandler(
                            success: true,
                            requestError: nil
                        )
                    }
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
    
    func getImagesForAlbum( completionHandler: ( success: Bool, albumError: NSError? ) -> Void )
    {
        // println( "Getting \( photoInfo.count ) images..." )
        
        // var photoAlbum = [ UIImage ]()
        // var photoAlbumCounter: Int = 0
        dispatch_sync( dispatch_get_global_queue( Int( QOS_CLASS_USER_INTERACTIVE.value ), 0 ) )
            {
                dispatch_sync( dispatch_get_global_queue( Int( QOS_CLASS_USER_INTERACTIVE.value ), 0 ) )
                    {
        for currentPhotoDictionary in self.currentAlbumPhotoInfo
        {
            println( "Getting the next photo dictionary..." )
            // get an actual image and append it to an array
            
            dispatch_sync( dispatch_get_global_queue( Int( QOS_CLASS_USER_INTERACTIVE.value ), 0 ) )
                {
            self.taskForImage( currentPhotoDictionary )
            {
                imageData, imageError in
                
                if imageError != nil
                {
                    completionHandler(
                        success: false,
                        albumError: imageError
                    )
                }
                else
                {
                    println( "Got an image!!!" )
                    // photoAlbum.append( UIImage( data: imageData! )! )
                    // println( "photoAlbum.count: \( photoAlbum.count )" )
                    self.currentAlbumImages.append( UIImage( data: imageData! )! )
                }
            }
            }
            
//            if photoAlbum.count == photoInfo.count
//            {
//                        println( "Returning \( photoAlbum.count ) images." )
//                        completionHandler(
//                            photoAlbum: photoAlbum,
//                            albumError: nil
//                        )
//            }
        }
                }
        
        // session.finishTasksAndInvalidate()
        
        // println( "Returning \( photoAlbum.count ) images." )
        dispatch_sync( dispatch_get_global_queue( Int( QOS_CLASS_USER_INTERACTIVE.value ), 0 ) )
            {
        completionHandler(
            success: true,
            albumError: nil
        )
        }
        }
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
