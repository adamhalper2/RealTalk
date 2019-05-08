//
//  MyChatsViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 5/1/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class MyChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //private var myChats = [Post]()
    private var myChatContent = [String]()
    private let db = Firestore.firestore()
    private var joinedChatIDs = [""]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myChatContent.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell")  as! ChatPreviewTableViewCell
        //let post = myChats[indexPath.row]
        //cell.contentCell.text = post.content
        let content = myChatContent[indexPath.row]
        cell.contentCell.text = content
        return cell
        /*if indexPath.row == 0 {
            //cell.coverPhoto.image  = UIImage(named: "heartBreak")
            cell.onlineIcon.text = "2 online"
            cell.unreadMessageLabel.text = "1 unread"
            return cell
        } else if indexPath.row == 1 {
            //cell.coverPhoto.image  = UIImage(named: "crazyGFIcon")
            cell.onlineIcon.text = "5 online"
            cell.unreadMessageLabel.text = "3 unread"
            cell.contentCell.text = "I've got an insane roommate. Help!"
            return cell
        } else {
            //cell.coverPhoto.image  = UIImage(named: "fbIcon")
            //cell.coverPhoto.sizeToFit()
            cell.onlineIcon.text = "3 online"
            cell.unreadMessageLabel.text = "16 unread"
            cell.contentCell.text = "Can anyone who's interviewed at Facebook/Instagram tell me what its like?"
            return cell
        }*/
    }


    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateMyChats()
    }
    
    func updateMyChats() {
        let currUser = AppController.user!
        let uid = currUser.uid
        let userRef = db.collection("students").document(uid)
        
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if let joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    print("*~*~users' joined chats: \(joinedChatIDsStr)")
                    self.joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                }
            }
        }
        
        /*for post in posts {
            
            if joinedChatIDs.contains(post.id) {
                myChats.append(post)
            }
        }*/
        
        for postID in joinedChatIDs {
            
            let postsRef = db.collection("channels").document(postID)
            
            postsRef.getDocument { (documentSnapshot, err) in
                if let err = err {
                    print("Error getting document: \(err)")
                } else {
                    guard let data = documentSnapshot?.data() else {return}
                    if let content = data["content"] {
                        self.myChatContent.append(content as! String)
                    } else {
                        print("couldn't get content of post")
                    }
                }
            }
        }
        
        self.tableView.reloadData()
    }

    /*func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = myChats[indexPath.row]
        let user = AppController.user
        let vc = ChatViewController(user: user!, post: post)
        self.navigationController?.pushViewController(vc, animated:true)
    }*/
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
