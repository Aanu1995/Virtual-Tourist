//
//  LocalStorage.swift
//  Virtual Tourist
//
//  Created by user on 20/03/2021.
//

import Foundation
import MapKit

protocol LocalStorage {
    func setRegion(center:CLLocationCoordinate2D, span: MKCoordinateSpan) -> Data
    func getRegion(data: Data) ->  MKCoordinateRegion
}

class LocalStorageImpl: LocalStorage {
    
    func setRegion(center:CLLocationCoordinate2D, span: MKCoordinateSpan) -> Data {
        let currentRegion = Region(latitude: center.latitude, longitude: center.longitude, latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(currentRegion)
        return data
    }
    
    func getRegion(data: Data) ->  MKCoordinateRegion {
        let decoder = JSONDecoder()
        let result = try! decoder.decode(Region.self, from: data)
        
        let center = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
        let span = MKCoordinateSpan(latitudeDelta: result.latitudeDelta, longitudeDelta: result.longitudeDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
    
}
