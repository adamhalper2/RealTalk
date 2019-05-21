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
    var heartCount = 0 {
        didSet {
            DispatchQueue.main.async {
                self.heartLabel.setTitle("\(self.heartCount)", for: .normal)
            }
        }
    }
    
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
            //removeButton.isEnabled = false
            //removeButton.alpha = 0.5;
            removeButton.isHidden = true
        } else {
            removeButton.isHidden = false
        }
        let banned = post?.bannedList.contains(message!.sender.id)
        if banned! {
            //removeButton.isEnabled = false
            removeButton.isHidden = true
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
        let alertController = UIAlertController(title: "", message: "Are you sure you want to flag this message?", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            self.addMessageReport()
            self.setReportedButton()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default) {
            UIAlertAction in
            alertController.dismiss(animated: true, completion: nil)
        })
        self.present(alertController, animated: true, completion: nil)
    }

    func setReportedButton() {
        self.flagButton.isEnabled = false
        self.flagButton.alpha = 1.0
        self.flagButton.backgroundColor = UIColor.lightGray
        self.flagButton.setTitle("Messaged reported.", for: .normal)
        self.flagButton.tintColor = UIColor.red
    }

    func checkIfUserReported() {
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

    func setHeartedButton() {
        self.heartButton.isEnabled = false
        self.heartButton.backgroundColor = UIColor.lightGray
        self.heartButton.setTitle("Love sent!", for: .normal)
        self.heartButton.tintColor = UIColor.red
    }


    func checkIfUserHearted() {
        guard let message = message else {return}
        guard let user = AppController.user else {return}

        let reportsRef = db.collection("hearts").whereField("postID", isEqualTo: message.id).whereField("fromID", isEqualTo: user.uid)
        reportsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if document.exists {
                        DispatchQueue.main.async {
                            self.setHeartedButton()
                            return
                        }
                    } else {
                        return
                    }
                }
            }
        }
    }

    func addHeartToPost() {
        guard let currUser = AppController.user else {return}
        let fromID = currUser.uid

        guard let currPost = post else {return}
        guard let postID = currPost.id else {return}
        guard let toID = currPost.authorID else {return}

        pushNotifyHeart(toID: toID)

        let newHeart = Heart(postID: postID, fromID: fromID, toID: toID, onPost: true)
        let  heartsRef =  db.collection("hearts")
        heartsRef.addDocument(data: newHeart.representation) //add heart to firestore
        let newHeartCount = currPost.heartCount + 1

        let postRef = db.collection("channels").document(postID) //update post's heart count in firestore
        postRef.updateData([
            "heartCount": String(newHeartCount)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("updated heart count to \(newHeartCount)")
            }
        }

        let userRef = db.collection("students").document(toID)
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if let oldCount = data["heartCount"] as? String {
                    print("old author heart count: \(oldCount)")
                    let oldCountInt = Int(oldCount)!
                    userRef.updateData(
                        ["heartCount": String(oldCountInt + 1)]
                    )
                    print("updated authors heart count to \(oldCountInt + 1)")
                }
            }
        }
    }

    func pushNotifyHeart(toID: String) {
        //print("load user token called. display name: \(AppSettings.displayName)")
        db.collection("students").document(toID)
            .getDocument { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }

                guard let content = self.post?.content else {return}
                guard let postID = self.post?.id else {return}
                guard let token = data["fcmToken"] as? String else {return}

                let sender = PushNotificationSender()
                guard let displayName = AppSettings.displayName else {return}
                sender.sendPushNotification(to: token, title: "\(displayName) liked your post", body: "\(content)", postID: postID, type: UserNotifs.heart.type(), userID: toID)
                print("notif sent")
        }
    }

    @IBAction func removePressed(_ sender: Any) {
        
        let alertController = UIAlertController(title: "", message: "Are you sure you want to remove this user?", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            self.removeUser()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default) {
            UIAlertAction in
            alertController.dismiss(animated: true, completion: nil)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func exitButtonPressed(_ sender: UIButton!) {
        print("exit button pressed")
        self.dismiss(animated:true, completion: nil)
    }
    
    @IBAction func heartTapped(_ sender: Any) {
        addHeartToPost()
        setHeartedButton()
    }

    func pushNotifyBannedUser(bannedID: String) {
        db.collection("students").document(bannedID)
            .getDocument { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }

                guard let content = self.post?.content else {return}
                guard let postID = self.post?.id else {return}
                guard let token = data["fcmToken"] as? String else {return}

                let sender = PushNotificationSender()
                sender.sendPushNotification(to: token, title: "You were removed from this chat", body: "\"\(content)\"", postID: postID, type: UserNotifs.remove.type(), userID: bannedID)
                print("banned notif sent")
        }

    }
    private func removeUser() {
        chatViewRef?.addBannedMember(uid: self.message!.sender.id)
        chatViewRef?.removeMember(uid: self.message!.sender.id)
        chatViewRef?.removeChatFromUserList(uid: self.message!.sender.id)
        removeButton.isEnabled = false
        removeButton.alpha = 0.5
        removeButton.setTitle("User Banned", for: .normal)
        pushNotifyBannedUser(bannedID: self.message!.sender.id)
    }

}
