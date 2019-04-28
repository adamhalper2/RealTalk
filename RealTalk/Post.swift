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
    var date: Date
    var commentCount: Int
    //var messages: [Messages]


    init(content: String, author: String) {
        self.content = content
        self.author = author
        self.date = Date()
        self.commentCount = 0
    }
}
