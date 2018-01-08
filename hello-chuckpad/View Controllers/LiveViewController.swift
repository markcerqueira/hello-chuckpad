//
//  LiveViewController.swift
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/6/18.
//

import UIKit

final class LiveViewController: UIViewController, ChuckPadLiveDelegate {
    
    @IBOutlet private var sessionGUIDLabel: UILabel!
    @IBOutlet private var connectToSessionButton: UIButton!
    @IBOutlet private var publishMessageButton: UIButton!
    
    private var liveSession: LiveSession?
    private var firstChuckPadLive: ChuckPadLive?

    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionGUIDLabel.isHidden = true
        connectToSessionButton.isHidden = true
        publishMessageButton.isHidden = true
    }
    
    // MARK: - IBActions
    
    @IBAction func createNewLiveSessionPressed() {
        ChuckPadSocial.sharedInstance().createLiveSession("My Live Session") { [weak self] (succeeded, liveSession, error) in
            self?.liveSession = liveSession
            self?.sessionGUIDLabel.text = liveSession?.sessionGUID
            
            self?.sessionGUIDLabel.isHidden = false
            self?.connectToSessionButton.isHidden = false
        }
    }
    
    @IBAction func connectToSessionPressed() {
        let demoLiveSession = LiveSession()
        demoLiveSession.sessionGUID = "demo_channel"
        
        let chuckPadLive = ChuckPadLive.initWith(demoLiveSession, chuckPadLiveDelegate: self)
        
        sessionGUIDLabel.text = "\(demoLiveSession.sessionGUID!) - Connected"
            
        publishMessageButton.isHidden = false
        
        if firstChuckPadLive == nil {
            firstChuckPadLive = chuckPadLive
        }
    }
    
    @IBAction func publishMessagePressed() {
        firstChuckPadLive?.publish("Hello Spencer!")
    }
    
    // MARK: - ChuckPadLiveDelegate
    
    func chuckPadLive(_ chuckPadLive: ChuckPadLive!, didReceive liveStatus: LiveStatus) {
        print("didReceive - \(liveStatus)")
    }
}
