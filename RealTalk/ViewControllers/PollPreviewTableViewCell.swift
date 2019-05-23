//
//  PollPreviewTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 5/22/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore


class PollPreviewTableViewCell: UITableViewCell {

    @IBOutlet weak var crownIcon: UIImageView!

    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var lockIcon: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!

    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatTitleLabel: UILabel!

    @IBOutlet weak var onlineIcon: UIImageView!
    @IBOutlet weak var onlineLabel: UILabel!

    @IBOutlet weak var pollView: UIView!
    @IBOutlet weak var optionAView: UIView!
    @IBOutlet weak var optionBView: UIView!
    @IBOutlet weak var optionALabel: UILabel!
    @IBOutlet weak var optionBLabel: UILabel!

    @IBOutlet weak var optionBPercentLabel: UILabel!
    @IBOutlet weak var optionAPercentLabel: UILabel!
    @IBOutlet weak var voteCountLabel: UILabel!

    var user = AppController.user!
    var poll: Poll?

    var votes : [Vote] = [] {
        didSet {
            DispatchQueue.main.async {
                if (self.hasVoted && self.votes.count > 0) {
                   // self.staticFill()
                }
                if self.votes.count == 1 {
                    self.voteCountLabel.text = "1 vote"
                } else {
                    self.voteCountLabel.text = "\(self.votes.count) votes"
                }
            }
        }
    }

    var hasVoted: Bool = false {
        didSet {
            print("did set hasVoted \(hasVoted)")
            if (hasVoted) {
                DispatchQueue.main.async {
                    self.animateFill()
                }

            }
        }
    }
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

    func loadVotes(pollID: String) {
        let votesRef = db.collection("votes").whereField("pollID", isEqualTo: pollID)
        votesRef.getDocuments { (querySnapshot, err) in
            if err != nil {
                print("Error getting votes from DB: \(err)")
            }
            guard let snap = querySnapshot else {return}
            for document in snap.documents {
                guard let vote = Vote(data: document.data(), docId: document.documentID) else {return}
                if !self.votes.contains(vote) {
                    self.votes.append(vote)
                    print("successfully loaded vote \(vote)")

                }
                if vote.senderID == self.user.uid {
                    if self.hasVoted == false {
                        self.hasVoted = true
                    }
                }
            }
        }
    }

    func setPoll(pollID: String) {

        if pollID == "" {return}
        let pollRef = db.collection("polls").document(pollID)
        pollRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                print("data for poll: \(data)")

                if let poll = Poll(data: data, docId: pollID) {
                    self.poll = poll
                    DispatchQueue.main.async {
                        print("option A label: \(poll.optionA)")
                        self.optionALabel.text = poll.optionA
                        self.optionBLabel.text = poll.optionB
                    }
                }
            }
        }
    }


    func setCell(post: Post) {
        self.post = post
        setPoll(pollID: post.pollID)
        loadVotes(pollID: post.pollID)
        optionALabel.addTapGesture(tapNumber: 1, target: self, action: #selector(voteForA))
        optionBLabel.addTapGesture(tapNumber: 1, target: self, action: #selector(voteForB))


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

    @objc func voteForA() {
        print("vote for A tapped")
        print("votes: \(votes)")
        guard let currPost = post else {return}
        let pollID = currPost.pollID

        //fillLayer(option: "A", fillWidth: 75.0)
        let vote = Vote(senderID: user.uid, option: true, pollID: pollID)
        let voteRef = db.collection("votes")
        voteRef.addDocument(data: vote.representation) { (err) in
            if (err != nil){
                print("Error getting document: \(err)")
            } else {
                print("added new vote for A")
                DispatchQueue.main.async {
                    self.addVote(vote)
                    self.animateFill()
                }
            }
        }
    }

    @objc func voteForB() {
        print("vote for B tapped")
        guard let currPost = post else {return}
        let pollID = currPost.pollID

        //fillLayer(option: "A", fillWidth: 75.0)
        let vote = Vote(senderID: user.uid, option: false, pollID: pollID)
        let voteRef = db.collection("votes")
        voteRef.addDocument(data: vote.representation) { (err) in
            if (err != nil){
                print("Error getting document: \(err)")
            } else {
                print("added new vote for B")
                DispatchQueue.main.async {
                    self.addVote(vote)
                    self.animateFill()
                }
            }
        }
    }

    private func addVote(_ vote: Vote) {
        guard !votes.contains(vote) else {
            return
        }
        print("addVote called")
        votes.append(vote)


    }

    func resetCell() {
        votes = [Vote]()
        voteCountLabel.text = "0 votes"
        optionAView.frame.size.width = 0
        optionBView.frame.size.width = 0
        hasVoted = false
        poll = nil
        post = nil
        optionAPercentLabel.isHidden = true
        optionBPercentLabel.isHidden = true
        optionALabel.text = ""
        optionBLabel.text = ""
        chatTitleLabel.text = ""
    }


    func setOnlineLabel() {
        if membersOnline.count > 1 {
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

    func staticFill() {
        print("static fill called")
        if votes.count <= 0 {return}
        let width = pollView.frame.size.width

        var votesForA : CGFloat = 0
        var votesForB : CGFloat = 0

        for vote in votes {
            if (vote.option) {
                votesForA += 1
            } else {
                votesForB += 1
            }
        }
        print("vote count is \(votes.count)")

        print("votesForA: \(votesForA), votesForB: \(votesForB)")

        let APercent : CGFloat = votesForA / (votesForA + votesForB)
        let BPercent : CGFloat = votesForB / (votesForA + votesForB)
        self.optionAPercentLabel.isHidden = false
        self.optionBPercentLabel.isHidden = false

        let AWidth = APercent * width
        let BWidth = BPercent * width

        print("APercent: \(APercent)")
        print("BPercent: \(BPercent)")

        let aPercentStr = "\(Int(APercent * 100))%"
        let bPercentStr = "\(Int(BPercent * 100))%"

        self.optionAPercentLabel.text = aPercentStr
        self.optionBPercentLabel.text = bPercentStr

        print("APercentStr: \(aPercentStr)")
        print("BPercentStr: \(bPercentStr)")

        self.optionAView.frame.size.width = AWidth
        self.optionBView.frame.size.width = BWidth
        self.layoutIfNeeded()
    }

    func animateFill() {
        if votes.count == 0 {
            print("vote count is zero")
            return
        }
        let width = pollView.frame.size.width

        var votesForA : CGFloat = 0
        var votesForB : CGFloat = 0

        for vote in votes {
            if (vote.option) {
                votesForA += 1
            } else {
                votesForB += 1
            }
        }
        print("vote count is \(votes.count)")

        print("votesForA: \(votesForA), votesForB: \(votesForB)")

        let APercent : CGFloat = votesForA / (votesForA + votesForB)
        let BPercent : CGFloat = votesForB / (votesForA + votesForB)
        self.optionAPercentLabel.isHidden = false
        self.optionBPercentLabel.isHidden = false

        let AWidth = APercent * width
        let BWidth = BPercent * width

        print("APercent: \(APercent)")
        print("BPercent: \(BPercent)")

        let aPercentStr = "\(Int(APercent * 100))%"
        let bPercentStr = "\(Int(BPercent * 100))%"

        self.optionAPercentLabel.text = aPercentStr
        self.optionBPercentLabel.text = bPercentStr

        print("APercentStr: \(aPercentStr)")
        print("BPercentStr: \(bPercentStr)")

        fillLayer(option: "A", fillWidth: AWidth)
        fillLayer(option: "B", fillWidth: BWidth)
    }

    @objc func fillLayer(option: String, fillWidth: CGFloat) {
        UIView.animate(withDuration: 1) {
            if option == "A" {
                print("setting a width \(fillWidth)")
                self.optionAView.frame.size.width = fillWidth
            } else  if option == "B" {
                print("setting B width \(fillWidth)")
                self.optionBView.frame.size.width = fillWidth
            }
        }
        self.layoutIfNeeded()
    }


}
