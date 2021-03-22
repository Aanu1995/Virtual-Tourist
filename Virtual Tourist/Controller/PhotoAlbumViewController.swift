//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, ErrorMessage {
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLabel: UILabel!
    var activityIndicator = UIActivityIndicatorView(style: .medium)

    
    var coordinate: CLLocationCoordinate2D!
    var currentSpan: MKCoordinateSpan!
    var photoservice: PhotoService!
    
    var photos: PhotoModel?
    var photoList: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoservice = PhotoServiceImpl()
        configure()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func configure(){
        navigationController?.navigationBar.isHidden = false
        activityIndicator.frame = CGRect(x: view.center.x - 23, y: view.center.y, width: 46, height: 46)
        view.addSubview(activityIndicator)
        configureMapView()
        loadImagesFromServer()
    }
    
    private func configureMapView(){
        mapView.centerCoordinate = coordinate
        mapView.region.span = currentSpan
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    private func loadImagesFromServer(){
        // shows loading indicator
        loading(true)
        var page = 1
        if let photos = photos {
            let allPhotos = photos.photos
            if(allPhotos.page < allPhotos.pages){
                page = allPhotos.page + 1
            }
        }
        photoservice.getAllPhotos(page: page, latitude: coordinate.latitude, longitude: coordinate.longitude, completionHandler: onPhotosFetchingCompleted)
    }
    
    private func onPhotosFetchingCompleted(result: PhotoModel? , error: Error?) {
        // hide loading indicators
        self.loading(false)
        if let error = error {
            return showErrorMessage(message: error.localizedDescription)
        }
        
        self.photos = result
        self.photoList = result?.photos.photoList ?? []
        // show message if photos is empty
        self.noImagesText()
       
        self.collectionView.refreshControl?.endRefreshing()
        self.collectionView.reloadData()
    }
    
    private func loading(_ isLoading: Bool){
        if isLoading {
            activityIndicator.startAnimating()
        }else {
            activityIndicator.stopAnimating()
        }
        
        collectionView.isHidden = isLoading
        noImageLabel.isHidden = isLoading
        newCollectionButton.isEnabled = !isLoading
    }
    
    private func showErrorMessage(message: String ) {
        present(displayErrorAlert(message: message), animated: true)
    }
    
    private func noImagesText(){
        let isPhotoListEmpty = photoList.isEmpty
        collectionView.isHidden = isPhotoListEmpty
        noImageLabel.isHidden = !isPhotoListEmpty
       
    }
    
    @IBAction func getNewPhotos(_ sender: Any) {
        loadImagesFromServer()
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

extension PhotoAlbumViewController: CollectionViewProtocols{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let url = photoList[indexPath.row].imageUrl
        photoservice.downloadImage(photoURL: url) { (data) in
            cell.configure(image: UIImage(data: data)!)
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalItems = 3
        let spacing = CGFloat(totalItems - 1) * 4.0
        let width = (collectionView.frame.width - spacing) / CGFloat(totalItems)
        let height = width + 20.0
        return CGSize(width: width, height: height)
    }
  
}
