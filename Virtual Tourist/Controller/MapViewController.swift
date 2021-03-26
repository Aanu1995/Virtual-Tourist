//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, HapticFeeback {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var touristMapView: MKMapView!
    
    // MARK: Properties
    
    let localStorage: LocalStorage = LocalStorageImpl()
    var dataController: DataController!
    var photoAlbumList: [PhotoAlbum] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.navigationBar.isHidden = true
        setupFetchedResultsController()
    }
    
    
    func configureMap(){
        // add a gesture recognizer to the map
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        touristMapView.addGestureRecognizer(longPressRecognizer)
        setupFetchedResultsController()
        getMapRegionFromStorage()
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            photoAlbumList = result
            addAnnotations(photoAlbumList: result)
        }
       
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
    
    private func addAnnotations(photoAlbumList: [PhotoAlbum]){
        var annotaions = [MKPointAnnotation]()
        for photoAlbum in photoAlbumList {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: photoAlbum.latitude, longitude: photoAlbum.longitude)
            annotaions.append(annotation)
        }
        
        touristMapView.addAnnotations(annotaions)
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
            destination.dataController = dataController
            let photoAlbum = photoAlbumList.first {$0.latitude == destination.coordinate.latitude && $0.longitude == destination.coordinate.longitude}
            destination.photoAlbum = photoAlbum
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

