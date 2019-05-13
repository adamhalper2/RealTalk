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
    
    @IBOutlet weak var heartLabel: UIButton!

    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var handleLabel: UILabel!
    
    @IBOutlet weak var heartButton: UIButton!
    
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
        checkIfUserReported()
        handleLabel.text = message?.sender.displayName
        messageLabel.text = message?.content
        getUserHearts()
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

    func getUserHearts(){
        guard let message = message else {return}
        let userRef = db.collection("students").document(message.sender.id)
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if let heartCount = data["heartCount"] as? String {
                    DispatchQueue.main.async {
                        self.heartLabel.setTitle("\(heartCount)", for: .normal)
                    }
                }
            }
        }

    }
    
    @IBAction func flagPressed(_ sender: Any) {
        self.addMessageReport()
        setReportedButton()
    }

    func setReportedButton() {
        self.flagButton.isEnabled = false
        self.flagButton.alpha = 1.0
        self.flagButton.backgroundColor = UIColor.lightGray
        self.flagButton.setTitle("Messaged reported.", for: .normal)
        self.flagButton.tintColor = UIColor.red
    }

    func checkIfUserReported() {
        guard let post = post else {return}
        guard let id = post.id else {return}
        guard let message = message else {return}
        guard let user = AppController.user else {return}

        let reportsRef = db.collection("reports").whereField("postID", isEqualTo: message.id).whereField("fromID", isEqualTo: user.uid)
        reportsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if document.exists {
                        DispatchQueue.main.async {
                            self.setReportedButton()
                            return
                        }
                    } else {
                        return
                    }
                }
            }
        }


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
            removeUser()
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
                print("updated report count to \(newReportCount)")
            }
        }


        //messageRef.getDocument(messageID)
    }

    @IBAction func removePressed(_ sender: Any) {
        removeUser()
    }
    
    @IBAction func heartTapped(_ sender: Any) {
        let uid = self.message!.sender.id
        let authorRef = db.collection("students").document(uid)
       // authorRef.updateData(<#T##fields: [AnyHashable : Any]##[AnyHashable : Any]#>)
    }

    private func removeUser() {
        chatViewRef?.addBannedMember(uid: self.message!.sender.id)
        chatViewRef?.removeMember(uid: self.message!.sender.id)
        chatViewRef?.removeChatToUserList()
        removeButton.isEnabled = false
        removeButton.alpha = 0.5
        removeButton.setTitle("User Banned", for: .normal)
    }

}
