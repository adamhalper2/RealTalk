//
//  Poll.swift
//  RealTalk
//
//  Created by Adam Halper on 5/21/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation

struct Poll {

    let id: String?
    let postID: String?
    let optionA: String
    let optionB: String
    var votes: [String]

    init(optionA: String, optionB: String) {
        self.id = nil
        self.postID = nil
        self.optionA = optionA
        self.optionB = optionB
        votes = []

    }

    init?(data: [String: Any], docId: String) {


        /*
        guard let postID = data["postID"] as? String else {
            return nil
        }
        */

        guard let optionA = data["optionA"] as? String else {
            return nil
        }

        guard let optionB = data["optionB"] as? String else {
            return nil
        }

        guard let votesStr = data["votes"] as? String else {
            return nil
        }
        let votes = votesStr.components(separatedBy: "-")

        self.id = docId
        self.postID = ""
        self.optionA = optionA
        self.optionB = optionB
        self.votes = votes
    }
}

extension Poll : DatabaseRepresentation {


    var representation: [String : Any] {
        var rep = ["postID": postID]
        rep["optionA"] = optionA
        rep["optionB"] = optionB
        rep["votes"] = votes.joined(separator: "-")

        if let id = id {
            rep["id"] = id
        }

        return rep
    }

}


    

