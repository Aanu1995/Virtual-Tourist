//
//  Constants.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import Foundation
import UIKit

// MARK: TypeAlias

typealias CollectionViewProtocols = UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

// MARK: Constants

struct Constants {
    
    struct FlickrApi {
        static let apiKey = "fd92039ce7f7fe617c5122bf45bb5626"
        static let baseUrl = "https://www.flickr.com/services/rest/"
        static let recentPhotos = "?method=flickr.photos.search&nojsoncallback=1"
    }
    
    struct UserDefaults {
        static let region = "region"
    }
    
    struct SegueIdentifier{
        static let mapViewToPhotoView = "mapViewToPhotoView"
    }
    
}
