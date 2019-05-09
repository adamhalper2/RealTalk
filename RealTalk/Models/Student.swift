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
    var isOnline: Bool
    var joinedChatIDs: [String]
    var fcmToken: String

    init(uid: String, username: String, bio: String?, createdDate: NSDate) {
        self.uid = uid
        self.username = username
        self.heartCount = 0
        self.bio = ""
        self.createdDate = createdDate
        self.isOnline = true
        self.joinedChatIDs = [""]
        if let userBio = bio {
            self.bio = userBio
        }
        self.fcmToken = ""
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let uid = data["uid"] as? String else {
            return nil
        }

        guard let username = data["username"] as? String else {
            return nil
        }

        guard let fcmToken = data["fcmToken"] as? String else {
            return nil
        }

        guard let bio = data["bio"] as? String else {
            return nil
        }

        guard let isOnline = data["isOnline"] as? String else {
            return nil
        }

        guard let isOnlineBool = Bool(isOnline) else {return nil}

        guard let heartCount = data["heartCount"] as? String else {
            return nil
        }
        let heartCountInt = Int(heartCount)!

        guard let createdDate = data["createdDate"] as? String else {
            return nil
        }
        
        guard let joinedChatIDsString = data["joinedChatIDs"] as? String else {
            return nil
        }
        let joinedChatIDs = joinedChatIDsString.components(separatedBy: "-")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy h:mm a Z"
        let date = dateFormatter.date(from: createdDate)! as NSDate

        self.uid = uid
        self.username = username
        self.fcmToken = fcmToken
        self.bio = bio
        self.isOnline = isOnlineBool
        self.heartCount = heartCountInt
        self.createdDate = date
        self.joinedChatIDs = joinedChatIDs

    }
    
}

extension Student: DatabaseRepresentation {

    var representation: [String : Any] {
        var rep: [String : Any] = [
            "uid": uid,
            "username": username,
            "fcmToken": fcmToken,
            "bio": bio,
            "isOnline": String(isOnline),
            "heartCount": String(heartCount),
            "createdDate": createdDate.toString(dateFormat: "MM/dd/yy h:mm a Z"),
            "joinedChatIDs": joinedChatIDs.joined(separator: "-")
        ]

        return rep
    }

}
