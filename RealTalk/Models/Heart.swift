//
//  Heart.swift
//  RealTalk
//
//  Created by Adam Halper on 5/1/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct Heart {
    var postID: String
    var fromID: String
    var toID: String
    var onPost: Bool //to know whether it was on post or chat


    init(postID: String, fromID: String, toID: String, onPost: Bool) {
        self.postID = postID
        self.fromID = fromID
        self.toID = toID
        self.onPost = onPost
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let postID = data["postID"] as? String else {
            return nil
        }
        guard let fromID = data["fromID"] as? String else {
            return nil
        }
        guard let toID = data["toID"] as? String else {
            return nil
        }
        guard let onPost = data["onPost"] as? Bool else {
            return nil
        }
        
        self.postID = postID
        self.fromID = fromID
        self.toID = toID
        self.onPost = onPost
    }

}

extension Heart : DatabaseRepresentation {

    var representation: [String : Any] {
        var rep = ["postID": postID]
        rep["fromID"] = fromID
        rep["toID"] = toID
        rep["onPost"] = String(onPost)
        return rep
    }

}

