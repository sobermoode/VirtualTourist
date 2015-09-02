//
//  PhotoAlbumCell.swift
//  VirtualTourist
//
//  Created by Aaron Justman on 8/20/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhotoAlbumCell: UICollectionViewCell
{
    // outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoImageView: UIImageView!
    
    // task for retrieving the image from Flickr
    var imageTask: NSURLSessionDataTask? = nil
    
    func taskForImage( url: NSURL )
    {
        imageTask = NSURLSession.sharedSession().dataTaskWithURL( url )
        {
            imageData, imageResponse, imageError in
            
            let cellImage = UIImage( data: imageData! )!
            self.photoImageView.image = cellImage
            
//            dispatch_async( dispatch_get_main_queue() )
//            {
//                self.photoImageView.image = cellImage
//            }
        }
        imageTask!.resume()
    }
}
