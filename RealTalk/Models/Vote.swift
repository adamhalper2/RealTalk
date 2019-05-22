//
//  Vote.swift
//  RealTalk
//
//  Created by Adam Halper on 5/21/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Vote {


    var senderID: String
    var option: Bool //option A = true, option B = false
    var pollID: String

    init(senderID: String, option: Bool, pollID: String) {
        self.senderID = senderID
        self.option = option
        self.pollID = pollID
    }

    init?(data: [String: Any], docId: String) {

        guard let senderID = data["senderID"] as? String else {
            return nil
        }

        guard let optionStr = data["option"] as? String else {
            return nil
        }
        guard let option = Bool(optionStr) else {return nil}

        guard let pollID = data["pollID"] as? String else {
            return nil
        }

        self.senderID = senderID
        self.option = option
        self.pollID = pollID
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let senderID = data["senderID"] as? String else {
            return nil
        }

        guard let optionStr = data["option"] as? String else {
            return nil
        }
        guard let option = Bool(optionStr) else {return nil}

        
        guard let pollID = data["pollID"] as? String else {
            return nil
        }

        self.senderID = senderID
        self.option = option
        self.pollID = pollID
    }
}

extension Vote :  DatabaseRepresentation {

    var representation: [String : Any] {
        var rep = ["senderID": senderID]
        rep["option"] = String(option)
        rep["pollID"] = pollID

        return rep
    }
}

extension Vote: Comparable {

    static func == (lhs: Vote, rhs: Vote) -> Bool {
        return lhs.senderID == rhs.senderID && lhs.pollID == rhs.pollID
    }

    static func < (lhs: Vote, rhs: Vote) -> Bool {
        return String(lhs.option) < String(rhs.option)
    }

}

