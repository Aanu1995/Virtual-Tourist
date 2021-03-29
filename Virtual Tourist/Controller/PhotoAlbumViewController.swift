//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by user on 05/03/2021.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, ErrorMessage, HapticFeeback {
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLabel: UILabel!

    // MARK: Properties
    
    var activityIndicator = UIActivityIndicatorView(style: .medium)
    
    var currentSpan: MKCoordinateSpan!
    var photoservice: PhotoService!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoservice = PhotoServiceImpl()
        setupFetchedResultsController()
        configureUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        try? dataController.viewContext.save()
        fetchedResultsController = nil
    }

    
    private func configureUI() {
        navigationController?.navigationBar.isHidden = false
        activityIndicator.frame = CGRect(x: view.center.x - 23, y: view.center.y, width: 46, height: 46)
        view.addSubview(activityIndicator)
        configureMapView()
    }
    
    private func configureMapView(){
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.centerCoordinate = coordinate
        mapView.region.span = currentSpan
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.latitude)\(pin.longitude)")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            loadImagesFromLocalStorage()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    private func loadImagesFromLocalStorage() {
        let result = fetchedResultsController.fetchedObjects
        
        if let result = result, result.isEmpty {
            // fetch images from flickr if there are no images in the local storage
            fetchImagesFromServer()
            return
        }
        self.showTextMessageIfEmpty(isPhotoListEmpty: false)
        self.collectionView.reloadData()
    }
    
    private func fetchImagesFromServer() {
        // shows loading indicator
        loading(true)
        photoservice.getAllPhotos(latitude: pin.latitude, longitude: pin.longitude, completionHandler: onFetchingImagesCompleted)
    }
    
    private func onFetchingImagesCompleted(result: PhotoModel? , error: Error?) {
        // remove all photos in the persistent store if exist
        deleteAllPhotos {
            // hide loading indicators
            self.loading(false)
            if let error = error {
                return self.showErrorMessage(message: error.localizedDescription)
            }
            
            let photoList: [String] = result?.photos.photoList.map({$0.imageUrl}) ?? []
            
            // add all photos to the persistent store
            if (!photoList.isEmpty) {
                for url in photoList {
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.pin = self.pin
                    photo.photoURL = url
                }
                try? self.dataController.viewContext.save()
                self.collectionView.reloadData()
            }
            
            // show message if photos is empty
            self.showTextMessageIfEmpty(isPhotoListEmpty: photoList.isEmpty)
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
    
    private func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    private func deleteAllPhotos(completionHandler: @escaping () -> Void ) {
        for photo in fetchedResultsController.fetchedObjects ?? [] {
            let indexPath = fetchedResultsController.indexPath(forObject: photo)
            deletePhoto(at: indexPath! )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
           completionHandler()
        }
    }
    
    @IBAction func getNewPhotos(_ sender: Any) {
        fetchImagesFromServer()
        selectionFeedback()
    }
}

// MARK: MKMapView

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

// MARK: UICollectionView

extension PhotoAlbumViewController: CollectionViewProtocols {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let photo: Photo = fetchedResultsController.object(at: indexPath)
        if let image = photo.image {
            cell.configure(image: UIImage(data: image)!)
        } else {
            // download image data and update if it doesn't exist in local storage
            if let photoURL = photo.photoURL {
                photoservice.downloadImage(photoURL: photoURL) { (data) in
                    cell.configure(image: UIImage(data: data)!)
                    photo.image = data
                }
            }
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
        selectionFeedback()
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
}

// MARK: CoreData

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .insert, .update, .move:
            break
        default:
            break
        }
    }
}




