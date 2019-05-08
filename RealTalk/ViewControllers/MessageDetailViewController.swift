//
//  MessageDetailViewController.swift
//  RealTalk
//
//  Created by Colin James Dolese on 5/7/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit

class MessageDetailViewController: UIViewController {
    
    @IBOutlet weak var flagButton: UIButton!
    
    @IBOutlet weak var removeButton: UIButton!
    
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var handleLabel: UILabel!
    
    var handleString: String?
    var messageString: String?
    var isOwner: Bool?
    
    static func instantiate() -> MessageDetailViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MessageDetailViewController") as? MessageDetailViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleLabel.text = handleString
        messageLabel.text = messageString
        
        if !isOwner! {
            removeButton.isEnabled = false
            removeButton.alpha = 0.5;

        }
        
    }
    
    @IBAction func flagPressed(_ sender: Any) {
        print("flagging!")
    }
    
    @IBAction func removePressed(_ sender: Any) {
        print("removing!")
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
