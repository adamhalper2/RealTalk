//
//  ChangeHandleViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 5/20/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase

class ChangeHandleViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var successLabel: UILabel!
    @IBOutlet weak var setBtn: UIButton!
    @IBOutlet weak var handleTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        successLabel.isHidden = true
        handleTextField.delegate = self
        if let name = AppSettings.displayName {
            handleTextField.text = name
        }
        // Do any additional setup after loading the view.
    }

    @IBAction func setTapped(_ sender: Any) {

        guard let user = AppController.user else {return}
        guard let newName = handleTextField.text else {return}
        let oldName = AppSettings.displayName ?? ""
        AppSettings.displayName = newName
        let db = Firestore.firestore()
        let userRef = db.collection("students").document(user.uid)
        userRef.updateData([
            "username": newName
        ]) { (err) in
            print("new name is \(newName)")
            if err != nil {
                print("Err updating handle: \(err)")
            } else {
                Analytics.logEvent("changed_handle", parameters: [
                    "user": user.uid as NSObject,
                    "newName": newName as NSObject,
                    "oldName": oldName as NSObject
                    ])

                self.successLabel.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.successLabel.isHidden = true
                }
            }
        }
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

}

