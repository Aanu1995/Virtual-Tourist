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
    var photoservice: PhotoService!
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoservice = PhotoServiceImpl()
        setupFetchedResultsController()
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
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            addAnnotations(pins: fetchedResultsController.fetchedObjects ?? [])
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == .began){
            let location = sender.location(in: touristMapView)
            let locationOnMap = touristMapView.convert(location, toCoordinateFrom: touristMapView)
            
            let pin = Pin(context: self.dataController.viewContext)
            pin.latitude = locationOnMap.latitude
            pin.longitude = locationOnMap.longitude
            try? self.dataController.viewContext.save()
        }
        
    }
    
    private func onPinAdded(indexPath: IndexPath) {
        let pin = fetchedResultsController.object(at: indexPath)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        impactFeedback(style: .heavy)
        touristMapView.addAnnotation(annotation)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchPhotosFromLocation(pin: pin, context: self.dataController.viewContext, service: self.photoservice)
        }
    }
    
    // set map region (center coordinate and the span)
    func getMapRegionFromStorage(){
        if let data = UserDefaults.standard.value(forKey: Constants.UserDefaults.region) as? Data {
            let region = localStorage.getRegion(data: data)
            touristMapView.setRegion(region, animated: true)
        }
    }
    
    private func addAnnotations(pins: [Pin]){
        var annotaions = [MKPointAnnotation]()
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
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
            destination.currentSpan = touristMapView.region.span
            destination.dataController = dataController
            let coord = sender as? CLLocationCoordinate2D
            let pinList = fetchedResultsController.fetchedObjects!
            let pin = pinList.first{$0.latitude == coord?.latitude && $0.longitude == coord?.longitude}
            destination.pin = pin
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
    
    private func fetchPhotosFromLocation(pin: Pin, context: NSManagedObjectContext, service: PhotoService){
        service.getAllPhotos(page: 1, latitude: pin.latitude, longitude: pin.longitude) { (photoModel, error) in
            if let _ = error { return }
        
            let photoList: [String] = photoModel?.photos.photoList.map({$0.imageUrl}) ?? []
            if (!photoList.isEmpty) {
                for url in photoList {
                    let photo = Photo(context: context)
                    photo.pin = pin
                    photo.photoURL = url
                }
                try? context.save()
            }
            
        }
    }
}

extension MapViewController : NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            onPinAdded(indexPath: newIndexPath!)
            break
        case .delete, .update, .move:
            break
        default:
            break
        }
    }
}


