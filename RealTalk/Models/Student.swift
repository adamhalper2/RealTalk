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
    var heartCount: Int
    var bio: String
    var createdDate: NSDate

    init(uid: String, username: String, bio: String?, createdDate: NSDate) {
        self.uid = uid
        self.username = username
        self.heartCount = 0
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
        guard let heartCount = data["heartCount"] as? String else {
            return nil
        }
        let heartCountInt = Int(heartCount)!

        guard let createdDate = data["createdDate"] as? String else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy h:mm a Z"
        let date = dateFormatter.date(from: createdDate)! as NSDate

        self.uid = uid
        self.username = username
        self.bio = bio
        self.heartCount = heartCountInt
        self.createdDate = date


    }
    
}

extension Student: DatabaseRepresentation {

    var representation: [String : Any] {
        var rep: [String : Any] = [
            "uid": uid,
            "username": username,
            "bio": bio,
            "heartCount": String(heartCount),
            "createdDate": createdDate.toString(dateFormat: "MM/dd/yy h:mm a Z")

        ]

        return rep
    }

}
