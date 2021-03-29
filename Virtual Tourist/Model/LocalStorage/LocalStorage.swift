//
//  LocalStorage.swift
//  Virtual Tourist
//
//  Created by user on 20/03/2021.
//

import Foundation
import MapKit

protocol LocalStorage {
    func saveData(center:CLLocationCoordinate2D, span: MKCoordinateSpan) -> Data
    func getData() ->  MKCoordinateRegion?
}

class LocalStorageImpl: LocalStorage {
    
    func saveData(center:CLLocationCoordinate2D, span: MKCoordinateSpan) -> Data {
        let currentRegion = Region(latitude: center.latitude, longitude: center.longitude, latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(currentRegion)
        return data
    }
    
    func getData() ->  MKCoordinateRegion? {
        if let data = UserDefaults.standard.value(forKey: Constants.UserDefaults.region) as? Data {
            let decoder = JSONDecoder()
            let result = try! decoder.decode(Region.self, from: data)
            
            let center = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
            let span = MKCoordinateSpan(latitudeDelta: result.latitudeDelta, longitudeDelta: result.longitudeDelta)
            return MKCoordinateRegion(center: center, span: span)
        }
        return nil
    }
    
}
