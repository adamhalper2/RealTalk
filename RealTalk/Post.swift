//
//  Post.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation

class Post {

    var author: String
    var content: String
    var timestamp: NSDate
    var commentCount: Int
    //var messages: [Messages]


    init(content: String, author: String, timestamp: NSDate) {
        self.content = content
        self.author = author
        self.timestamp = timestamp
        self.commentCount = 0
    }
}
