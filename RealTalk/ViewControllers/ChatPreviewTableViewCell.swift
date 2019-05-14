//
//  ChatPreviewTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 5/1/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit

class ChatPreviewTableViewCell: UITableViewCell {

    @IBOutlet weak var onlineIcon: UILabel!

    @IBOutlet weak var unreadMessageLabel: UILabel!
    @IBOutlet weak var crownIcon: UIImageView!
    
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
