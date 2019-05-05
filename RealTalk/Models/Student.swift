//
//  User.swift
//  RealTalk
//
//  Created by Adam Halper on 5/2/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct Student {

    let uid: String
    var username: String
    var karma: [String]
    var bio: String
    var createdDate: Date

    init(uid: String, username: String, bio: String?, createdDate: Date) {
        self.uid = uid
        self.username = username
        self.karma = []
        self.bio = ""
        self.createdDate = createdDate
        
        if let userBio = bio {
            self.bio = userBio
        }
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let uid = data["uid"] as? String else {
            return nil
        }
        guard let username = data["username"] as? String else {
            return nil
        }
        guard let bio = data["bio"] as? String else {
            return nil
        }
        guard let karma = data["karma"] as? [String] else {
            return nil
        }
        guard let createdDate = data["createdDate"] as? Date else {
            return nil
        }

        self.uid = uid
        self.username = username
        self.bio = bio
        self.karma = karma
        self.createdDate = createdDate

    }
    
}

extension Student: DatabaseRepresentation {

    var representation: [String : Any] {
        var rep: [String : Any] = [
            "uid": uid,
            "username": username,
            "bio": bio,
            "karma": karma,
            "createdDate": createdDate
        ]

        return rep
    }

}
