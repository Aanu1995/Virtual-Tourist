//
//  ErrorMessage.swift
//  Virtual Tourist
//
//  Created by user on 22/03/2021.
//

import Foundation
import UIKit

protocol ErrorMessage {
    
}

extension ErrorMessage {
    
    func displayErrorAlert(title: String = "Error", message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alert
    }
}
