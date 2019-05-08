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

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var heartBtn: UIButton!
    @IBOutlet weak var heartCountLabel: UILabel!
    @IBOutlet weak var reportBtn: UIButton!
    @IBOutlet weak var onlineIndicator: UIImageView!

    let filledHeart = UIImage(named: "filledHeart")
    let unfilledHeart = UIImage(named: "unfilledHeart")
    var post: Post?
    private let db = Firestore.firestore()
    let user = AppController.user!

    func setCell(post: Post) {

        self.post = post
        let memberLabel = getMemberNames(members: post.members, author: post.author)
        authorLabel.text = memberLabel
        contentLabel.text = post.content
        let date = post.timestamp
        let timestamp = timeAgoSinceDate(date: date, numericDates: true)
        timeLabel.text = timestamp
        commentBtn.setTitle(String(post.commentCount), for: .normal)
        heartCountLabel.text = String(post.heartCount)
        selectionStyle = UITableViewCell.SelectionStyle.none
        reportBtn.tintColor = UIColor.darkGray
        checkIfUserHearted()
        checkIfUserReported()
        checkIfMembersOnline()
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
                    print("invalid data from authors ref")
                    return
                }
                print("data is \(data)")
                guard let isOnlineStr = data["isOnline"] as? String else {
                    print("no isOnline field")
                    return
                }
                guard let isOnline = Bool(isOnlineStr) else {
                    print("unable to convert to bool")
                    return
                }
                DispatchQueue.main.async {
                    if (isOnline) {
                        print("setting author status to ONLINE")
                        self.onlineIndicator.tintColor = UIColor.green
                    } else {
                        print("setting author status to OFFLINE")
                        self.onlineIndicator.tintColor = UIColor.darkGray
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
        heartBtn.setImage(unfilledHeart, for: .normal)
        reportBtn.tintColor = UIColor.darkGray
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
                            self.heartBtn.setImage(self.filledHeart, for: .normal)
                            return
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.heartBtn.isEnabled = true
                            self.heartBtn.setImage(self.unfilledHeart, for: .normal)
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

        let reportCount = currPost.reportCount
        let heartCount = currPost.heartCount
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
        if heartBtn.image(for: .normal) == unfilledHeart {
            UIView.animate(withDuration: 0.01, animations: {
                self.heartBtn.alpha = 0.0
            }, completion:{(finished) in
                self.heartBtn.setImage(self.filledHeart, for: .normal)
                UIView.animate(withDuration: 0.1,animations:{
                    self.heartBtn.alpha = 1.0
                },completion:nil)
            })
            //heartBtn.setImage(filledHeart, for: .normal)
            //heartBtn.isEnabled = false
            addHeartToPost()
        }
    }

    func addHeartToPost() {
        guard let currUser = AppController.user else {return}
        let fromID = currUser.uid

        guard let currPost = post else {return}
        guard let postID = currPost.id else {return}
        guard let toID = currPost.authorID else {return}

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

    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = NSDate()
        let earliest = now.earlierDate(date as Date)
        let latest = (earliest == now as Date) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)
        if (components.year! >= 2) {
            return "\(components.year!)y"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 yr"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!)mo"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!)w"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1w"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!)d"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1d"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!)h"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1h"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!)min"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 min ago"
            } else {
                return "A min ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!)s"
        } else {
            return "Just now"
        }
    }
}
