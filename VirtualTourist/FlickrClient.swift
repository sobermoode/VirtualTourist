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
    
    func requestResultsForLocation(
        location: CLLocationCoordinate2D,
        completionHandler: ( ( requestError: NSError! ) -> Void )
    )
    {
        println( "requestResultsForDestination..." )
        
        let requestURL = createQueryURL( location )
        let requestTask = session.dataTaskWithURL( requestURL )
        {
            requestData, requestResponse, requestError in
            
            if requestError != nil
            {
                return completionHandler( requestError: requestError )
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
                    println( "Parsing results from Flickr..." )
                    // println( "requestResults: \( requestResults )" )
                    let photos = requestResults[ "photos" ] as! [ String : AnyObject ]
                    let photoArray = photos[ "photo" ] as! [[ String : AnyObject ]]
                    
                    var photoResults = [[ String : AnyObject ]]()
                    var resultCounter = ( photoArray.count > self.maxImagesToShow ) ? self.maxImagesToShow - 1 : photoArray.count
                    for counter in 0...resultCounter
                    {
                        // println( "index: \( index )" )
                        photoResults.append( photoArray[ counter ] )
                        // println( "Adding \( photoArray[ index ] )" )
                        // println( "self.albumPhotos.count: \( self.albumPhotos.count )" )
                        // returnImages.append( photoArray[ index ] )
                    }
                    // self.albumForDestinationID.updateValue( albumPhotos, forKey: self.destination.pinNumber )
                    println( "photoResults: \( photoResults )" )
                    
                    dispatch_async( dispatch_get_main_queue() )
                        {
                            self.albumPhotos = photoResults
                    }
                    
                    
                    return completionHandler( requestError: nil )
                }
                else
                {
                    let errorDictionary = [ NSLocalizedDescriptionKey : "There was an error with the request results from Flickr." ]
                    let requestError = NSError(
                        domain: "Virtual Tourist",
                        code: 2112,
                        userInfo: errorDictionary
                    )
                    return completionHandler( requestError: requestError )
                }
            }
        }
        requestTask.resume()
    }
    
    func getPhotoResults() -> [[ String : AnyObject ]]
    {
        return albumPhotos
    }
}
