//
//  ChatPreviewTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 5/1/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatPreviewTableViewCell: UITableViewCell {

    @IBOutlet weak var crownIcon: UIImageView!
    
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var lockIcon: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatTitleLabel: UILabel!

    @IBOutlet weak var onlineIcon: UIImageView!
    @IBOutlet weak var onlineLabel: UILabel!
    var post: Post?
    private let db = Firestore.firestore()
    var membersOnline: [Student] = [] {
        didSet {
            DispatchQueue.main.async {
                self.setOnlineLabel()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setCell(post: Post) {
        self.post = post

        chatTitleLabel.text = post.content
        lastMessageLabel.text = post.lastMessage

        let currUser = AppController.user!
        let uid = currUser.uid
        if post.authorID == currUser.uid {
            crownIcon.isHidden = false
            authorLabel.text = "You"
            crownIcon.tintColor = UIColor.customPurple2

        } else {
            crownIcon.isHidden = false
            crownIcon.tintColor = UIColor.lightGray
            authorLabel.text = post.author
            authorLabel.isHidden = false
        }
        lockIcon.tintColor = UIColor.darkGray
        if post.isLocked {
            lockIcon.isHidden = false
        } else {
            lockIcon.isHidden = true
        }

        loadMembers(memberIds: post.members)
        let memberCount = post.members.count
        if post.members.count == 1 {
            membersCountLabel.text = String(memberCount) + " member"
        } else {
            membersCountLabel.text = String(memberCount) + " members"
        }




    }

    func setOnlineLabel() {
        if membersOnline.count > 0 {
            onlineIcon.isHidden = false
            onlineLabel.isHidden = false
            onlineLabel.text = "\(membersOnline.count) online"
            onlineIcon.tintColor = UIColor.greenHighlight
        } else {
            onlineIcon.isHidden = true
            onlineLabel.isHidden = true
        }
    }

    func loadMembers(memberIds: [String]) {
        print("member count is \(memberIds.count)")
        for member in memberIds {
            let userRef = db.collection("students").document(member)
            userRef.getDocument { (documentSnapshot, err) in
                guard let snapshot = documentSnapshot else {
                    print("Error listening for channel updates: \(err?.localizedDescription ?? "No error")")
                    return
                }
                guard let data = snapshot.data() else {return}
                if let student = Student(data: data) {

                    print(student)
                    print("added student \(student)")
                    if student.isOnline && !self.membersOnline.contains(student) {
                        self.membersOnline.append(student)
                    }
                }
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
