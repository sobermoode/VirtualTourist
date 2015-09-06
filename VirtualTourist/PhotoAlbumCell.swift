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
    
    // var didGetImage: Bool = false
    
    // task for retrieving the image from Flickr
    var imageTask: NSURLSessionDataTask? = nil
}
