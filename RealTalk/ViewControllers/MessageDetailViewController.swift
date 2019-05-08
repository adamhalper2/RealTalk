//
//  MessageDetailViewController.swift
//  RealTalk
//
//  Created by Colin James Dolese on 5/7/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

class MessageDetailViewController: UIViewController {
    
    @IBOutlet weak var flagButton: UIButton!
    
    @IBOutlet weak var removeButton: UIButton!
    
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var handleLabel: UILabel!
    
    var isOwner: Bool?
    var message: Message?
    var chatViewRef: ChatViewController?
    var post: Post?
    private let db = Firestore.firestore()

    
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
        let refreshAlert = UIAlertController(title: "Report Message", message: "Are you sure you want to report this message?", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.addMessageReport()
            print("Thanks! This message is under review")
            self.flagButton.isEnabled = false

        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(refreshAlert, animated: true, completion: nil)

        print("flagging!")
    }

    func addMessageReport() {
        guard let currPost = post else {return}
        guard let postID = currPost.id else {return}

        guard let message = message else {return}
        let toID = message.sender.id
        let messageID = message.messageId
        guard let user = AppController.user else {return}
        let fromID = user.uid

        let newReport = Report(postID: messageID, fromID: fromID, toID: toID, onPost: false)

        //Adds report object to FB
        let reportsRef = db.collection("reports")
        reportsRef.addDocument(data: newReport.representation)

        //Auto-hides post if 4 or more reports
        var isActive = true
        if message.reportCount > 3 {
            print("reportCount > 3! removing post from feed")
            isActive = false
        }
        let newReportCount = message.reportCount + 1

        //Updates the message's reportCount and isActive fields
        let messageRef = db.collection(["channels", postID, "thread"].joined(separator: "/")).document(messageID)
        messageRef.updateData([
            "reportCount": String(newReportCount),
            "isActive": String(isActive)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("updated heart count to \(newReportCount)")
            }
        }


        //messageRef.getDocument(messageID)
    }

    @IBAction func removePressed(_ sender: Any) {
        chatViewRef?.addBannedMember(uid: self.message!.sender.id)
        chatViewRef?.removeMember(uid: self.message!.sender.id)
        removeButton.isEnabled = false
        removeButton.alpha = 0.5;
        removeButton.setTitle("User Banned", for: .normal)
    }

}
