//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController, HapticFeeback {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var touristMapView: MKMapView!
    let localStorage: LocalStorage = LocalStorageImpl()
    
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
        
        getMapRegionFromStorage()
    }
    
    
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == .began){
            let location = sender.location(in: touristMapView)
            let locationOnMap = touristMapView.convert(location, toCoordinateFrom: touristMapView)
            
            // To add anotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationOnMap
            
            impactFeedback(style: .heavy)
            self.touristMapView.addAnnotation(annotation)
        }
        
    }
    
    // set map region (center coordinate and the span)
    func getMapRegionFromStorage(){
        if let data = UserDefaults.standard.value(forKey: Constants.UserDefaults.region) as? Data {
            let region = localStorage.getRegion(data: data)
            touristMapView.setRegion(region, animated: true)
        }
    }
    
    
    // save the map region to local storage
    func persistMapRegion(region: MKCoordinateRegion) {
        let center = region.center
        let span = region.span
        DispatchQueue.global().async {
            let data = self.localStorage.setRegion(center: center, span: span)
            UserDefaults.standard.setValue(data, forKey: Constants.UserDefaults.region)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == Constants.SegueIdentifier.mapViewToPhotoView){
            let destination = segue.destination as! PhotoAlbumViewController
            destination.coordinate = sender as? CLLocationCoordinate2D
            destination.currentSpan = touristMapView.region.span
        }
    }


}


extension MapViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        persistMapRegion(region: mapView.region)
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
        view.setSelected(false, animated: false)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}


extension MapViewController: UIGestureRecognizerDelegate {
   
}
