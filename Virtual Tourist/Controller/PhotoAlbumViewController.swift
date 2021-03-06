//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var coordinate: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        navigationController?.navigationBar.isHidden = false
        configureMapView()
    }
    
    func configureMapView(){
        mapView.centerCoordinate = coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}


extension PhotoAlbumViewController : MKMapViewDelegate {
    
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
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
   
}
