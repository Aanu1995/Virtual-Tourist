//
//  PhotoModel.swift
//  Virtual Tourist
//
//  Created by user on 22/03/2021.
//

import Foundation

struct PhotoModel: Decodable {
    let photos: Photos
    
    struct Photos: Decodable {
        let page: Int
        let pages: Int
        let perPage: Int
        let photoList: [Image]
        
        enum CodingKeys: String, CodingKey {
            case page = "page"
            case pages = "pages"
            case perPage = "perpage"
            case photoList = "photo"
        }
    }
}

struct Image: Decodable {
    let id: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case imageUrl = "url_s"
    }
}
