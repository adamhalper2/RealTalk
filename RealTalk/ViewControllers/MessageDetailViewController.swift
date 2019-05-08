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
    
    var isOwner: Bool?
    var message: Message?
    var chatViewRef: ChatViewController?
    var post: Post?
    
    static func instantiate() -> MessageDetailViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MessageDetailViewController") as? MessageDetailViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleLabel.text = message?.sender.displayName
        messageLabel.text = message?.content
        
        if !isOwner! {
            removeButton.isEnabled = false
            removeButton.alpha = 0.5;

        }
        let banned = post?.bannedList.contains(message!.sender.id)
        if banned! {
            removeButton.isEnabled = false
            removeButton.alpha = 0.5;
            removeButton.setTitle("User Banned", for: .normal)
        }
        
    }
    
    @IBAction func flagPressed(_ sender: Any) {
        print("flagging!")
    }
    
    @IBAction func removePressed(_ sender: Any) {
        chatViewRef?.addBannedMember(uid: self.message!.sender.id)
        chatViewRef?.removeMember(uid: self.message!.sender.id)
        removeButton.isEnabled = false
        removeButton.alpha = 0.5;
        removeButton.setTitle("User Banned", for: .normal)
    }

}
