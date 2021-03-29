//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by user on 22/03/2021.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "PhotoCollectionViewCell"
    
    @IBOutlet weak var photoView: UIImageView!
    
    
    static func nib() -> UINib{
        return UINib(nibName: self.identifier, bundle: nil)
    }
    
    func configure(image: UIImage) {
        self.photoView.image = image
    }
}
