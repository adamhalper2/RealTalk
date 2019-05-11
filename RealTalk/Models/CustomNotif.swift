//  CustomNotif.swift
//  RealTalk
//
//  Created by Adam Halper on 5/9/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation
import FirebaseFirestore


class CustomNotif {

    var notifID: String?
    var body: String
    var timestamp: NSDate
    var type: String?
    var title: String
    var postID: String?
    var read: Bool

    init(body: String, timestamp: NSDate, type: String, title: String, postID: String?, read: Bool, notifID: String) {
        self.body = body
        self.timestamp = timestamp
        self.type = type
        self.title = title
        self.postID = postID ?? ""
        self.read = read
        self.notifID = notifID
    }

    init?(data: [String: Any]) {

        guard let notifID = data["notifID"] as? String else {
            return nil
        }

        guard let body = data["body"] as? String else {
            return nil
        }

        guard let timestamp = data["timestamp"] as? String else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy h:mm a Z"
        var date = NSDate()
        if let realDate = dateFormatter.date(from: timestamp) as? NSDate {
            date = realDate
        }

        guard let title = data["title"] as? String else {
            return nil
        }

        guard let type = data["type"] as? String else {
            return nil
        }

        guard let read = data["read"] as? String else {
            return nil
        }
        guard let isRead = Bool(read) else {return nil}

        guard let postID = data["postID"] as? String else {return nil}

        self.body = body
        self.timestamp = date
        self.title = title
        self.type = type
        self.read = isRead
        self.postID = postID
        self.notifID = notifID
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let notifID = data["notifID"] as? String else {
            return nil
        }

        guard let body = data["body"] as? String else {
            return nil
        }

        guard let timestamp = data["timestamp"] as? String else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy h:mm a Z"
        var date = NSDate()
        if let realDate = dateFormatter.date(from: timestamp) as? NSDate {
            date = realDate
        }

        guard let title = data["title"] as? String else {
            return nil
        }

        guard let type = data["type"] as? String else {
            return nil
        }

        guard let read = data["read"] as? String else {
            return nil
        }
        guard let isRead = Bool(read) else {return nil}

        guard let postID = data["postID"] as? String else {return nil}



        self.body = body
        self.timestamp = date
        self.title = title
        self.type = type
        self.read = isRead
        self.postID = postID
        self.notifID = notifID
    }
}

extension CustomNotif : DatabaseRepresentation {


    var representation: [String : Any] {
        var rep = ["body": body]
        rep["title"] = title
        rep["timestamp"] = timestamp.toString(dateFormat: "MM/dd/yy h:mm a Z")
        rep["type"] = type
        rep["postID"] = postID
        rep["read"] = String(read)
        rep["notifID"] = notifID
        return rep
    }
}

extension CustomNotif: Comparable {

    static func == (lhs: CustomNotif, rhs: CustomNotif) -> Bool {
        return lhs.notifID == rhs.notifID
    }

    static func < (lhs: CustomNotif, rhs: CustomNotif) -> Bool {
        return rhs.timestamp < lhs.timestamp
    }

}

