//
//  OnlineOfflineManager.swift
//  RealTalk
//
//  Created by Adam Halper on 5/7/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct OnlineOfflineManager {


    func markUserOffline() {
        guard let user = AppController.user else {return}
        let db = Firestore.firestore()

        let isOnline = false
        db.collection("students").document(user.uid).updateData([
            "isOnline" : String(isOnline)
        ]) { (err) in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("updated online status to \(isOnline)")
            }
        }
    }

    func markUserOnline() {
        guard let user = AppController.user else {return}
        let db = Firestore.firestore()
        let isOnline = true
        db.collection("students").document(user.uid).setData([ "isOnline": String(isOnline)], merge: true)
        print("updated online status to true")

    }
}
