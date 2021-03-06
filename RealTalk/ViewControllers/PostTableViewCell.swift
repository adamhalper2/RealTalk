//
//  PostTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD
import Firebase

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var heartBtn: UIButton!
    @IBOutlet weak var heartCountLabel: UILabel!

    @IBOutlet weak var commentBtn: UIButton!
    
    @IBOutlet weak var reportBtn: UIButton!
    @IBOutlet weak var onlineIndicator: UIImageView!
    @IBOutlet weak var lockIndicator: UIImageView!
    @IBOutlet weak var moderatorIcon: UIImageView!
    
    //let filledHeart = UIImage(named: "filledHeart")
    // let unfilledHeart = UIImage(named: "unfilledHeart")
    var post: Post?
    private let db = Firestore.firestore()
    let user = AppController.user!
    let dateHelper = DateHelper()

    func setCell(post: Post) {

        self.post = post
        let memberLabel = getMemberNames(members: post.members, author: post.author)
        authorLabel.text = memberLabel
        contentLabel.text = post.content
        let date = post.timestamp
        let timestamp = dateHelper.timeAgoSinceDate(date: date, numericDates: true)
        timeLabel.text = timestamp
        if post.commentCount == 0 {
            commentBtn.setTitle(" ", for: .normal)
        } else {
            commentBtn.setTitle(String(post.commentCount), for: .normal)
        }
        heartCountLabel.text = String(post.heartCount)
        selectionStyle = UITableViewCell.SelectionStyle.none
        reportBtn.tintColor = UIColor.darkGray
        checkIfUserHearted()
        checkIfUserReported()
        checkIfMembersOnline()
        checkIfUserIsModerator()

        lockIndicator.tintColor = UIColor.darkGray
        print("post.isLocked is \(post.isLocked)")
        if post.isLocked == true {
            print("locked indicator hidden = true")
            lockIndicator.isHidden = false
        } else {
            print("locked indicator hidden = false")
            lockIndicator.isHidden = true
        }
    }
    
    
    func checkIfUserIsModerator() {
        guard let post = post else {return}
        guard let authorID = post.authorID else {return}
        guard let currUser = AppController.user else {return}
        if currUser.uid == authorID {
            onlineIndicator.isHidden = true
            moderatorIcon.tintColor = UIColor.customPurple2
            moderatorIcon.isHidden = false
        } else {
            onlineIndicator.isHidden = false
            moderatorIcon.isHidden = true
        }
    }

    func checkIfMembersOnline() {
        guard let post = post else {return}
        guard let authorID = post.authorID else {return}
        let authorRef = db.collection("students").document(authorID)
        print("getting author ref")
        authorRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {
                    return
                }
                guard let isOnlineStr = data["isOnline"] as? String else {
                    return
                }
                guard let isOnline = Bool(isOnlineStr) else {
                    return
                }
                DispatchQueue.main.async {
                    if (isOnline) {
                        self.onlineIndicator.tintColor = UIColor.customGreen
                    } else {
                        self.onlineIndicator.tintColor = UIColor.lightGray
                    }
                    return
                }
            }
        }
    }

    func getMemberNames(members: [String], author: String)->String? {
        var memberLabel = author
        if members.count > 2 {
            memberLabel = author + " and \(members.count - 1) others in chat"
            return memberLabel
        } else if members.count > 1 {
            memberLabel = author + " and 1 other in chat"
        }
        return memberLabel
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        heartBtn.tintColor = UIColor.groupTableViewBackground
        heartBtn.isEnabled = true
        reportBtn.tintColor = UIColor.darkGray
        reportBtn.isEnabled = true
        onlineIndicator.tintColor = UIColor.lightGray

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func checkIfUserHearted() {
        guard let post = post else {return}
        guard let id = post.id else {return}

        let heartsRef = db.collection("hearts").whereField("postID", isEqualTo: id).whereField("fromID", isEqualTo: user.uid).whereField("onPost", isEqualTo: "true")
        heartsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {

                    if document.exists {
                        DispatchQueue.main.async {
                            self.heartBtn.isEnabled = false
                            print("heart button disabled for post \(post.content)")
                            self.heartBtn.tintColor = UIColor.customPurple.withAlphaComponent(0.5)
                            return
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.heartBtn.isEnabled = true
                            print("heart button enabled for post \(post.content)")
                            self.heartBtn.tintColor = UIColor.groupTableViewBackground
                            return
                        }
                    }
                }
            }
        }
    }

    func checkIfUserReported() {
        guard let post = post else {return}
        guard let id = post.id else {return}

        let reportsRef = db.collection("reports").whereField("postID", isEqualTo: id).whereField("fromID", isEqualTo: user.uid)
        //.whereField("onPost", isEqualTo: "true")
        reportsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if document.exists {
                        DispatchQueue.main.async {
                            self.reportBtn.tintColor = UIColor.red
                            self.reportBtn.isEnabled = false
                            return
                        }
                    } else {
                        return
                    }
                }
            }
        }
    }

    @IBAction func reportTapped(_ sender: Any) {
        reportBtn.isEnabled = false
        let refreshAlert = UIAlertController(title: "Report Post", message: "Are you sure you want to report this post?", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.addReport()

            print("Thanks! This post is under review")
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.reportBtn.isEnabled = true
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(refreshAlert, animated: true, completion: nil)
    }




    func addReport() {
        guard let currPost = post else {return}
        guard let postID = currPost.id else {return}
        guard let toID = currPost.authorID else {return}
        let fromID = user.uid

        let newReport = Report(postID: postID, fromID: fromID, toID: toID, onPost: true)
        let reportsRef = db.collection("reports")
        reportsRef.addDocument(data: newReport.representation)

        Analytics.logEvent("add_report", parameters: [
            "sender": AppController.user!.uid as NSObject,
            "reportedPost": currPost.content as NSObject,
            "reportedAuthor": toID as NSObject
            ])

        let reportCount = currPost.reportCount
        var isActive = true
        reportBtn.tintColor = UIColor.red

        if reportCount > 3 {
            print("reportCount > 3! removing post from feed")
            isActive = false
        }

        let postRef = db.collection("channels").document(postID)
        let newReportCount = reportCount + 1
        postRef.updateData([
            "reportCount": String(reportCount + 1),
            "isActive": String(isActive)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("updated report count to \(newReportCount)")
            }
        }
    }

    @IBAction func heartTapped(_ sender: Any) {
        print("heart tapped")
        heartBtn.tintColor = UIColor.customPurple.withAlphaComponent(0.5)
        heartBtn.isEnabled = false
        addHeartToPost()
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
                sender.sendPushNotification(to: token, title: "\(displayName) liked your post", body: "\"\(content)\"", postID: postID, type: UserNotifs.heart.type(), userID: toID)
                print("notif sent")
        }
    }

    func addHeartToPost() {
        guard let currUser = AppController.user else {return}
        let fromID = currUser.uid

        guard let currPost = post else {return}
        guard let postID = currPost.id else {return}
        guard let toID = currPost.authorID else {return}
        if fromID != toID {
            pushNotifyHeart(toID: toID)
        }

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
}
