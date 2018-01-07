//
//  LiveViewController.swift
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/6/18.
//

import UIKit

final class LiveViewController: UIViewController {
    
    @IBOutlet private var sessionGUIDLabel: UILabel!
    
    private var liveSession: LiveSession?
    
    // MARK: - IBActions
    
    @IBAction func createNewLiveSessionPressed() {
        ChuckPadSocial.sharedInstance().createLiveSession("My Live Session") { [weak self] (succeeded, liveSession, error) in
            self?.liveSession = liveSession
            self?.sessionGUIDLabel.text = liveSession?.sessionGUID
        }
    }
}
