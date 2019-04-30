//
//  PostTableViewCell.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit

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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func heartTapped(_ sender: Any) {
        if heartBtn.image(for: .normal) == filledHeart {
            heartBtn.setImage(unfilledHeart, for: .normal)
        } else {
            heartBtn.setImage(filledHeart, for: .normal)
        }
    }
}
