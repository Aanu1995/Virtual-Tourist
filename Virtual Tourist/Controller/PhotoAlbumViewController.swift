//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, ErrorMessage {
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLabel: UILabel!
    var activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: Properties
    
    var coordinate: CLLocationCoordinate2D!
    var currentSpan: MKCoordinateSpan!
    var photoservice: PhotoService!
    var photos: PhotoModel?
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var photoAlbum: PhotoAlbum?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoservice = PhotoServiceImpl()
        setupFetchedResultsController()
        configure()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func configure() {
        navigationController?.navigationBar.isHidden = false
        activityIndicator.frame = CGRect(x: view.center.x - 23, y: view.center.y, width: 46, height: 46)
        view.addSubview(activityIndicator)
        configureMapView()
        loadImagesFromLocalStorage()
    }
    
    private func configureMapView(){
        mapView.centerCoordinate = coordinate
        mapView.region.span = currentSpan
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func setupFetchedResultsController() {
        guard let photoAlbum = photoAlbum else {
            return
        }
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "photoAlbum == %@", photoAlbum)
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(coordinate.latitude)\(coordinate.longitude)")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    private func loadImagesFromLocalStorage() {
        guard let _ = photoAlbum else {
            loadImagesFromServer()
            return
        }
        self.showTextMessageIfEmpty(isPhotoListEmpty: false)
        self.collectionView.reloadData()
    }
    
    private func loadImagesFromServer() {
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
        let photoList: [String] = result?.photos.photoList.map({$0.imageUrl}) ?? []
        // show message if photos is empty
        self.showTextMessageIfEmpty(isPhotoListEmpty: photoList.isEmpty)
      
            if (!photoList.isEmpty) {
                if photoAlbum != nil {
//                    let photoLength = fetchedResultsController.sections?[0].numberOfObjects
//                    for i in 0..<photoLength! {
//                        let photoToDelete = fetchedResultsController.object(at: IndexPath(row: i, section: 0))
//                        dataController.viewContext.delete(photoToDelete)
//                    }
//                    try? dataController.viewContext.save()
//                    for url in photoList {
//                        let photo = Photo(context: dataController.viewContext)
//                        photo.photoAlbum = photoAlbum
//                        photo.photoURL = url
//                    }
//                    try? dataController.viewContext.save()
                    
                } else {
                    let photoAlbum = PhotoAlbum(context: dataController.viewContext)
                    photoAlbum.latitude = coordinate.latitude
                    photoAlbum.longitude = coordinate.longitude
                    try? dataController.viewContext.save()
                    self.photoAlbum = photoAlbum
                    setupFetchedResultsController()
                    
                    for url in photoList {
                        let photo = Photo(context: dataController.viewContext)
                        photo.photoAlbum = photoAlbum
                        photo.photoURL = url
                    }
                    try? dataController.viewContext.save()
                }
            }
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
    
    private func showTextMessageIfEmpty(isPhotoListEmpty: Bool){
        collectionView.isHidden = isPhotoListEmpty
        noImageLabel.isHidden = !isPhotoListEmpty
       
    }
    
    @IBAction func getNewPhotos(_ sender: Any) {
        loadImagesFromServer()
    }
    
    func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
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
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let fetchedResultsController = fetchedResultsController else {
            return 0
        }
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let url = fetchedResultsController.object(at: indexPath).photoURL!
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(at: indexPath)
    }
    
}

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .insert:
            collectionView.reloadData()
            break
        case .update:
            collectionView.reloadData()
            break
        case .move:
            break
        default:
            break
        }
    }
}


