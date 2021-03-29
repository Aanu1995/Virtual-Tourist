//
//  Endpoints.swift
//  Virtual Tourist
//
//  Created by user on 22/03/2021.
//

import Foundation

enum Endpoints {
    case flickrPhotos (Int, Double, Double)
    
    var stringValue: String {
        let baseUrl = Constants.FlickrApi.baseUrl
        let recentPhotos = Constants.FlickrApi.recentPhotos
        let apiKey = Constants.FlickrApi.apiKey
        let perPage = 30
        
        switch self {
        case .flickrPhotos(let page, let lat, let long): return baseUrl + recentPhotos + "&api_key=\(apiKey)" + "&extras=url_s" + "&per_page=\(perPage)" + "&page=\(page)" + "&format=json" + "&lat=\(lat)&lon=\(long)"
        }
    }
    
    var url: URL {
        return URL(string: self.stringValue)!
    }
}
