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
    @IBOutlet weak var charCountLabel: UILabel!


    @IBOutlet weak var createPollBtn: UIButton!
    @IBOutlet weak var pollView: UIView! {
        didSet {
            if pollView.isHidden == false {
                if optionAField.text == "" || optionBField.text == "" {
                    shareBtn.isEnabled = false
                } else {
                    shareBtn.isEnabled = true
                }
            }
        }
    }
    @IBOutlet weak var optionAField: TextField!
    @IBOutlet weak var optionBField: TextField!


    let colors = Colors()
    var charLimit = 280
    var post = Post(content: "", author: AppSettings.displayName, timestamp: NSDate(), authorID: "")



    override func viewDidLoad() {
        super.viewDidLoad()

        pollView.isHidden = true
        textView.delegate = self
        textView.textColor = UIColor.lightGray

        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "DIN Alternate", size: 25)!]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.tabBarController?.tabBar.isHidden = true

        // Show keyboard by default
       // textView.becomeFirstResponder()
    }

    @IBAction func createPollTapped(_ sender: Any) {
        if pollView.isHidden {
            pollView.isHidden = false
            charLimit = 140

            /*
            if optionAField.text == "" || optionBField.text == "" {
                shareBtn.isEnabled = false
            } else {
                shareBtn.isEnabled = true
            }
            */
        } else {
            pollView.isHidden = true
            charLimit = 280
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= charLimit
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
        charCountLabel.text = "\(charLimit - textView.text.characters.count)"

        if textView.textColor != UIColor.lightGray && !textView.text.isEmpty {
            shareBtn.isEnabled = true
            shareBtn.setTitleColor(colors.customPurple, for: .normal)
        } else {
            shareBtn.isEnabled = false
            shareBtn.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }
    
    func sendDataToDatabase(content: String){
        let db = Firestore.firestore()
        let  postsReference =  db.collection("channels")

        var author = ""
        var uid = ""
        if let user = AppController.user {
            uid = user.uid
            if let username = user.displayName {
                author = username
            }

        } else {
            print("user is nil")
        }

        print("\n\nERROR author is \(author)\n\n")

        post = Post(content: content, author: AppSettings.displayName, timestamp: NSDate(), authorID: uid)
        print(post.timestamp)

        var docRef: DocumentReference? = nil
        docRef = postsReference.addDocument(data: post.representation) { error in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                    return
            }
        }
        
        let postID = docRef!.documentID

        
        let userRef = db.collection("students").document(uid)
        
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if var joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    var postCountInt = 0
                    if let postCount = data["postCount"] as? String {
                        postCountInt = Int(postCount)!
                    }
                    postCountInt += 1

                    var joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                    if (!joinedChatIDs.contains(postID)) {
                        joinedChatIDs.append(postID)
                    }
                    joinedChatIDsStr = joinedChatIDs.joined(separator: "-")
                    userRef.updateData(
                        ["joinedChatIDs": joinedChatIDsStr,
                        "postCount": String(postCountInt)])
                }
            }
        }
    }

    func sendDataToDatabasePoll(poll: Poll, content: String){


        let db = Firestore.firestore()
        let pollRef =  db.collection("polls")
        var pollDocRef: DocumentReference? = nil

        pollDocRef = pollRef.addDocument(data: poll.representation) { error in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
        }

        let pollID = pollDocRef!.documentID

        let  postsReference =  db.collection("channels")

        var author = ""
        var uid = ""
        if let user = AppController.user {
            uid = user.uid
            if let username = user.displayName {
                author = username
            }

        }

        post = Post(content: content, author: AppSettings.displayName, timestamp: NSDate(), authorID: uid, pollID: pollID)
        print(post.timestamp)

        var docRef: DocumentReference? = nil
        docRef = postsReference.addDocument(data: post.representation) { error in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
        }

        let postID = docRef!.documentID

        let userRef = db.collection("students").document(uid)

        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if var joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    var postCountInt = 0
                    if let postCount = data["postCount"] as? String {
                        postCountInt = Int(postCount)!
                    }
                    postCountInt += 1

                    var joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                    if (!joinedChatIDs.contains(postID)) {
                        joinedChatIDs.append(postID)
                    }
                    joinedChatIDsStr = joinedChatIDs.joined(separator: "-")
                    userRef.updateData(
                        ["joinedChatIDs": joinedChatIDsStr,
                         "postCount": String(postCountInt)])
                }
            }
        }
    }

    @IBAction func closeTapped(_ sender: Any) {
        print("close tapped")
        tabBarController!.selectedIndex = 0
        self.tabBarController?.tabBar.isHidden = false

    }

    @IBAction func shareTapped(_ sender: Any) {
        guard let content = textView.text else {return}
        guard let optionA = optionAField.text else {return}
        guard let optionB = optionBField.text else {return}

        if pollView.isHidden {
            sendDataToDatabase(content: content)
        } else if optionA == "" && optionB == "" {
            sendDataToDatabase(content: content)
        } else if optionA == "" || optionB == "" {
                let alertController = UIAlertController(title: "", message: "You need to add two options for your poll!", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) {
                    UIAlertAction in
                    self.dismiss(animated: true, completion: nil)
                })
                self.present(alertController, animated: true, completion: nil)
                return
        } else {
            let poll = Poll(optionA: optionA, optionB: optionB)
            sendDataToDatabasePoll(poll: poll, content: content)
        }

        textView.text = "I wanna talk with someone about..."
        textView.textColor = UIColor.lightGray
        optionAField.text = ""
        optionBField.text = ""
        Analytics.logEvent("share_post", parameters: [
            "name": AppController.user!.uid as NSObject,
            "full_text": textView.text as NSObject
            ])

        tabBarController!.selectedIndex = 0
        let alertController = UIAlertController(title: "", message: "You are now the moderator of your new chat, so you can remove members, delete the chat, or lock the chat to prevent new users from seeing or joining it.", preferredStyle: UIAlertController.Style.alert)
        /*alertController.addAction(UIAlertAction(title: "Go to chat", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            let user = AppController.user
            let vc = ChatViewController(user: user!, post: self.post)
            self.navigationController?.pushViewController(vc, animated:true)
        })*/
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.dismiss(animated: true, completion: nil)
        })
        
        if let user = AppController.user {
            let db = Firestore.firestore()
            let userRef = db.collection("students").document(user.uid)
            userRef.getDocument { (documentSnapshot, err) in
                if let err = err {
                    print("Error getting document: \(err)")
                } else {
                    guard let data = documentSnapshot?.data() else {return}
                    if let numPosts = data["postCount"] as? String {
                        let numPostsInt = Int(numPosts)
                        print("*~*~user post count: \(numPosts)")
                        
                        if numPostsInt == 0 {
                            print("num posts = \(numPosts)")
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            print("user is nil")
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
