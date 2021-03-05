//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController{

    @IBOutlet weak var touristMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
    }
    
    func configureMap(){
        navigationController?.navigationBar.isHidden = true
        setRegion()
    }
    
    // set map region (center coordinate and the span)
    func setRegion(){
        if let data = UserDefaults.standard.value(forKey: Constants.UserDefaults.region) as? [Double] {

            let center = CLLocationCoordinate2D(latitude: data[0], longitude: data[1])
            let span = MKCoordinateSpan(latitudeDelta: data[2], longitudeDelta: data[3])

            let region = MKCoordinateRegion(center: center, span: span)
            touristMapView.setRegion(region, animated: true)
        }
    }
    
    
    // save the map center coordinate and the span lat and long delta in a list
    func saveRegion(region: MKCoordinateRegion) {
        let center = region.center
        let span = region.span
        let data: [Double] = [center.latitude, center.longitude, span.latitudeDelta, span.longitudeDelta]
        UserDefaults.standard.setValue(data, forKey: Constants.UserDefaults.region)
    }


}


extension MapViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveRegion(region: mapView.region)
    }
}

