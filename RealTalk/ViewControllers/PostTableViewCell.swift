//
//  PostTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var reportBtn: UIImageView!
    @IBOutlet weak var heartBtn: UIButton!
    @IBOutlet weak var heartCountLabel: UILabel!

    let filledHeart = UIImage(named: "filledHeart")
    let unfilledHeart = UIImage(named: "unfilledHeart")
    var post: Post?
    private let db = Firestore.firestore()


    func setCell(post: Post) {

        self.post = post
        let memberLabel = getMemberNames(members: post.members, author: post.author)
        authorLabel.text = memberLabel
        contentLabel.text = post.content
        let date = post.timestamp
        let timestamp = timeAgoSinceDate(date: date, numericDates: true)
        timeLabel.text = timestamp
        print("comment count at table view: \(post.commentCount)")
        commentBtn.setTitle(String(post.commentCount), for: .normal)
        heartCountLabel.text = String(post.heartCount)
        selectionStyle = UITableViewCell.SelectionStyle.none
        checkIfUserHearted()
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func checkIfUserHearted() {
        print("check if user hearted called")
        guard let currUser = AppController.user else {return}
        guard let post = post else {return}
        guard let id = post.id else {return}
        print("post id is \(id)")

        let heartsRef = db.collection("hearts").whereField("postID", isEqualTo: id).whereField("fromID", isEqualTo: currUser.uid)
            //.whereField("onChat", isEqualTo: "true").whereField("fromID", isEqualTo: currUser.uid)
        heartsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if document.exists {
                        print("heart from query: \(document.documentID) => \(document.data())")
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            self.heartBtn.isEnabled = false
                            self.heartBtn.setImage(self.filledHeart, for: .normal)
                            return
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            self.heartBtn.isEnabled = true
                            self.heartBtn.setImage(self.unfilledHeart, for: .normal)
                            return
                        }

                        }
                }
            }
        }


        // 1. Get all hearts on postID...where on post = true...where current userID matches from ID
        // 2. Check if currenet user ID matches fromID
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

        let newHeartCount = Int(currPost.heartCount) + 1


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
