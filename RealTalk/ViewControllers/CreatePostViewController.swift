//
//  CreatePostViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD
import FirebaseAuth

class CreatePostViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!

    let colors = Colors()

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        textView.textColor = UIColor.lightGray
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.tabBarController?.tabBar.isHidden = true

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
    
    func sendDataToDatabase(photoUrl: String, content: String){
        let db = Firestore.firestore()
        let  postsReference =  db.collection("channels")

        var author = "mrBean"
        var uid = ""
        if let user = Auth.auth().currentUser {
            uid = user.uid
            print("user.uid is \(user.uid)")
            if let username = user.displayName {
                print("username is \(username)")

                author = username
            }

        } else {
            print("user is nil")
        }

        print("author is \(author)")

        let post = Post(content: content, author: AppSettings.displayName, timestamp: NSDate(), authorID: uid)
        print(post.timestamp)

        postsReference.addDocument(data: post.representation) { error in
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

    @IBAction func closeTapped(_ sender: Any) {
        print("close tapped")
        tabBarController!.selectedIndex = 0
        self.tabBarController?.tabBar.isHidden = false

    }

    @IBAction func shareTapped(_ sender: Any) {
        if let content = textView.text {
            let photoUrl = "samplePhotoUrl"
            sendDataToDatabase(photoUrl: photoUrl, content: content)
            textView.text = "I wanna talk with someone about..."
            textView.textColor = UIColor.lightGray
        }
        tabBarController!.selectedIndex = 0
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
