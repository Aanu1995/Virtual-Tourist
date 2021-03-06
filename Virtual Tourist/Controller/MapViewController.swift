//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController{
    
    // MARK: IBOutlets
    
    @IBOutlet weak var touristMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }
    
    func configureMap(){
       
        // add a gesture recognizer to the map
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        touristMapView.addGestureRecognizer(longPressRecognizer)
        
        setRegion()
    }
    
    
    @objc func onLongPress(sender: UIGestureRecognizer) {
        if (sender.state == .began){
            let location = sender.location(in: touristMapView)
            let locationOnMap = touristMapView.convert(location, toCoordinateFrom: touristMapView)
            
            // To add anotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationOnMap
            self.touristMapView.addAnnotation(annotation)
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == Constants.SegueIdentifier.mapViewToPhotoView){
            let destination = segue.destination as! PhotoAlbumViewController
            destination.coordinate = sender as? CLLocationCoordinate2D
        }
    }


}


extension MapViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveRegion(region: mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: Constants.SegueIdentifier.mapViewToPhotoView, sender: view.annotation?.coordinate)
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
}

