//
//  HapticFeedback.swift
//  Virtual Tourist
//
//  Created by user on 21/03/2021.
//

import Foundation
import UIKit

protocol HapticFeeback {
}

extension HapticFeeback {
    
    func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let feedback =  UIImpactFeedbackGenerator(style: style)
        feedback.prepare()
        feedback.impactOccurred()
    }
    
    func selectionFeedback() {
        let feedback =  UISelectionFeedbackGenerator()
        feedback.prepare()
        feedback.selectionChanged()
    }
}
