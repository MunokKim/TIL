//
//  EmotionsViewController.swift
//  FaceIt
//
//  Created by 김문옥 on 2018. 1. 13..
//  Copyright © 2018년 김문옥. All rights reserved.
//

import UIKit

class EmotionsViewController: UIViewController
{
    private let emotionalFaces: Dictionary<String, FacialExpression> = [
        "angry" : FacialExpression(eyes: .Closed, eyeBrows: .Furrowed, mouth: .Frown),
        "happy" : FacialExpression(eyes: .Open, eyeBrows: .Normal, mouth: .Smile),
        "worried" : FacialExpression(eyes: .Open, eyeBrows: .Relaxed, mouth: .Smirk),
        "mischi" : FacialExpression(eyes: .Open, eyeBrows: .Furrowed, mouth: .Grin),
    ]
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationvc = segue.destination
        
        if let navcon = destinationvc as? UINavigationController {
            destinationvc = navcon.visibleViewController ?? destinationvc
        }
        
        if let facevc = destinationvc as? FaceViewController {
            if let identifier = segue.identifier {
                if let expression  = emotionalFaces[identifier] {
                    facevc.expression = expression
                    if let sendingButton = sender as? UIButton {
                        facevc.navigationItem.title = sendingButton.currentTitle
                    }
                }
            }
        }
    }

}
