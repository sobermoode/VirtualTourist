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
    var albumPhotos = [[ String : AnyObject ]]()
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
        completionHandler: ( photoAlbum: [ UIImage ]?, zeroResults: Bool, photoAlbumError: NSError? ) -> Void
    )
    {
        requestResultsForLocation( location )
        {
            photoInfo, requestError in
            
            if requestError != nil
            {
                completionHandler(
                    photoAlbum: nil,
                    zeroResults: false,
                    photoAlbumError: requestError
                )
            }
            else
            {
                self.getImagesForAlbum( photoInfo )
                {
                    photoAlbum, albumError in
                    
                    if albumError != nil
                    {
                        completionHandler(
                            photoAlbum: nil,
                            zeroResults: false,
                            photoAlbumError: albumError
                        )
                    }
                    else
                    {
                        if photoAlbum?.count == 0
                        {
                            completionHandler(
                                photoAlbum: photoAlbum,
                                zeroResults: true,
                                photoAlbumError: nil
                            )
                        }
                        else
                        {
                            completionHandler(
                                photoAlbum: photoAlbum,
                                zeroResults: false,
                                photoAlbumError: nil
                            )
                        }
                    }
                }
            }
        }
    }
    
    func requestResultsForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( photoInfo: [ [ String : AnyObject ] ], requestError: NSError! ) -> Void
    )
    {
        println( "requestResultsForDestination..." )
        
        var photoInfo = [ [ String : AnyObject ] ]()
        // var imageResults: [ UIImage ]?
        
        let requestURL = createQueryURL( location )
        let requestTask = session.dataTaskWithURL( requestURL )
        {
            requestData, requestResponse, requestError in
            
            if requestError != nil
            {
                completionHandler(
                    photoInfo: photoInfo,
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
                            resultCounter = 1
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
                        // i had to cast the Slice into the type i actually want to use
                        // check out https://stackoverflow.com/questions/24073269/what-is-a-slice-in-swift for more
                        photoInfo = [ [ String : AnyObject ] ]( photoArray[ 0...resultCounter ] )
                        
                        /*
                        for ( index, currentPhotoDictionary ) in enumerate( photoArray )
                        {
                            if index > resultCounter
                            {
                                break
                            }
                            else
                            {
                                photoInfo.append( currentPhotoDictionary )
                            }
                            
                            // println( index, currentPhotoDictionary )
                        }
                        */
                        
                        /*
                        for photoInfo in photoResults
                        {
                            // get an actual image and append it to an array
                            let currentImageTask = self.taskForImage(photoInfo)
                            {
                                imageData, imageError in
                                
                                if imageError != nil
                                {
                                    completionHandler(photoResults: <#[[String : AnyObject]?]#>, requestError: <#NSError!#>)
                                }
                                else
                                {
                                    
                                }
                            }
                        }
                        */
                    }
                    // self.albumForDestinationID.updateValue( albumPhotos, forKey: self.destination.pinNumber )
                    // println( "photoResults: \( photoResults )" )
                    
                    completionHandler(
                        photoInfo: photoInfo,
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
                        photoInfo: photoInfo,
                        requestError: requestError
                    )
                }
            }
        }
        requestTask.resume()
    }
    
    func getImagesForAlbum(
        photoInfo: [ [ String : AnyObject ] ],
        completionHandler: ( photoAlbum: [ UIImage ]?, albumError: NSError? ) -> Void
    )
    {
        println( "Getting \( photoInfo.count ) images..." )
        
        var photoAlbum = [ UIImage ]()
        // var photoAlbumCounter: Int = 0
        
        for currentPhotoDictionary in photoInfo
        {
            println( "Getting the next photo dictionary..." )
            // get an actual image and append it to an array
                self.taskForImage( currentPhotoDictionary )
                {
                    imageData, imageError in
                    
                    if imageError != nil
                    {
                        completionHandler(
                            photoAlbum: nil,
                            albumError: imageError
                        )
                    }
                    else
                    {
                        println( "Got an image!!!" )
                            photoAlbum.append( UIImage( data: imageData! )! )
                            println( "photoAlbum.count: \( photoAlbum.count )" )
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
        
        // session.finishTasksAndInvalidate()
        
        println( "Returning \( photoAlbum.count ) images." )
        completionHandler(
            photoAlbum: photoAlbum,
            albumError: nil
        )
    }
    
    func taskForImage(
        imageInfo: [ String : AnyObject ],
        completionHandler: ( imageData: NSData?, imageError: NSError? ) -> Void
    ) -> NSURLSessionDataTask
    {
        let farmID = imageInfo[ "farm" ] as! Int
        let serverID = imageInfo[ "server" ] as! String
        let photoID = imageInfo[ "id" ] as! String
        let secret = imageInfo[ "secret" ] as! String
        
        let imageURLString = "https://farm\( farmID ).staticflickr.com/\( serverID )/\( photoID )_\( secret ).jpg"
        let imageURL = NSURL( string: imageURLString )!
        
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
        
        return imageTask
    }
    
    func getPhotoResults() -> [[ String : AnyObject ]]
    {
        return albumPhotos
    }
}
