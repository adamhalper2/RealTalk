//
//  CreatePostViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD
import Firebase

class CreatePostViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!

    let colors = Colors()
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        textView.textColor = UIColor.lightGray
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)



        // Show keyboard by default
       // textView.becomeFirstResponder()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }



    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        textView.endEditing(true)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        print("did begin editing")
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "I wanna talk with someone about..."
            textView.textColor = UIColor.lightGray
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.textColor != UIColor.lightGray && !textView.text.isEmpty {
            shareBtn.isEnabled = true
            shareBtn.setTitleColor(colors.customGreen, for: .normal)
        } else {
            shareBtn.isEnabled = false
            shareBtn.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }

    func sendPostToDB(photoUrl: String, content: String){

        let timestamp = NSDate().timeIntervalSince1970

        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        ref = db.collection("posts").addDocument(data: [
            "photo": photoUrl,
            "content": content,
            "userID": "1234",
            "timestamp": "\(timestamp)"
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                ProgressHUD.showError(err.localizedDescription)

            } else {
                ProgressHUD.showSuccess("Success")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                    self.tabBarController!.selectedIndex = 0
                })
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }

    /*

    func sendDataToDatabase(photoUrl: String, content: String){
        let ref = Database.database().reference()
        let postsReference = ref.child("posts")
        let newPostID = postsReference.childByAutoId().key
        let newPostReference = postsReference.child(newPostID!)
        //newPostReference.setValue(["photoUrl": photoUrl, "caption": caption, "userID": Auth.auth().currentUser?.uid])
        var timestamp = NSDate().timeIntervalSince1970


        newPostReference.setValue(["photoUrl": photoUrl, "content": content, "userID": "mrBean", "date": "\(timestamp)"]) { (error, ref) in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            ProgressHUD.showSuccess("Success")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                //go to feed
            })
        }
    }
*/
    @IBAction func closeTapped(_ sender: Any) {
        print("close tapped")
        tabBarController!.selectedIndex = 0

      //  tabBarController?.selectedIndex = 1

    }

    @IBAction func shareTapped(_ sender: Any) {
        if let content = textView.text {
            let photoUrl = "samplePhotoUrl"
            sendPostToDB(photoUrl: photoUrl, content: content)
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
