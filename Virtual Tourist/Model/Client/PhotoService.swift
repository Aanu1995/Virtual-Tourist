//
//  PhotoService.swift
//  Virtual Tourist
//
//  Created by user on 22/03/2021.
//

import Foundation

protocol PhotoService {
    func getAllPhotos(latitude: Double, longitude: Double, completionHandler: @escaping (PhotoModel?, Error?) -> Void )
    func downloadImage(photoURL: String, completionHandler handler: @escaping (_ data: Data) -> Void)
}

class PhotoServiceImpl: PhotoService {
    
    func getAllPhotos(latitude: Double, longitude: Double, completionHandler: @escaping (PhotoModel?, Error?) -> Void) {
        let page = Int.random(in: 1..<4)
        let url: URL = Endpoints.flickrPhotos(page, latitude, longitude).url
       
        
        taskForGetRequest(url: url) { (data, error) in
            guard let data = data else {
                return completionHandler(nil, error)
            }
            
            let decoder = JSONDecoder()
            
            do {
                let result = try decoder.decode(PhotoModel.self, from: data)
                return completionHandler(result, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
    
    func downloadImage(photoURL: String, completionHandler: @escaping (_ data: Data) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
          
            if let url = URL(string: photoURL), let imgData = try? Data(contentsOf: url) {
               
                DispatchQueue.main.async {
                    completionHandler(imgData)
                }
            }
        }
    }
    
    private func taskForGetRequest (url:URL, completionHandler: @escaping (Data?, Error?) -> Void){
        
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                    return
                }
                
                
                DispatchQueue.main.async {
                    completionHandler(data, nil)
                }
            }
            task.resume()
        }
}
