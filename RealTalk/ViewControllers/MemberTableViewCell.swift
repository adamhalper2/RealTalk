//
//  MemberTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 5/16/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit


protocol MemberCellDelegate {
    func memberCellTapped(userID: String)
}

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var hearts: UIButton!
    @IBOutlet weak var onlineIndicator: UIImageView!
    @IBOutlet weak var memberIcon: UIImageView!
    @IBOutlet weak var xIcon: UIButton!

    var chatViewRef: ChatViewController?
    var delegate: MemberCellDelegate?
    var user: Student?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setCell(user: Student, post: Post) {
        self.user = user
        name.text = user.username
        let heartCountStr = String(user.heartCount)
        hearts.setTitle(heartCountStr, for: .normal)

        if (user.isOnline) {
            onlineIndicator.tintColor = UIColor.greenHighlight
        } else {
            onlineIndicator.tintColor = UIColor.lightGray
        }

        guard let currUser = AppController.user else {return}
        
        if user.uid == post.authorID {
            memberIcon.image = UIImage(named: "crownIcon")
            memberIcon.tintColor = .customPurple2
            xIcon.isHidden = false
        } else {
            memberIcon.image = UIImage(named: "memberAvatar")
            memberIcon.tintColor = .lightGray

            xIcon.isHidden = true
        }

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func removeMemberTapped(_ sender: Any) {
        xIcon.isEnabled = false
        xIcon.alpha = 0.5
        xIcon.setTitle("User Banned", for: .normal)
        if let removedUser = user {
            delegate?.memberCellTapped(userID: removedUser.uid)
        }
    }

}
