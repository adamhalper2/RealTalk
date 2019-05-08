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

    private var posts = [Post]()
    private var postsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var joinedChatIDs = [""]
    private var uid = ""
    
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as! ChatPreviewTableViewCell
        let post = posts[indexPath.row]
        cell.contentCell.text = post.content
        cell.onlineIcon.text = "2 online"
        cell.unreadMessageLabel.text = "1 unread"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let user = AppController.user
        let userId = user?.uid
        let vc = ChatViewController(user: user!, post: post)
        self.navigationController?.pushViewController(vc, animated:true)
    }
    
    deinit {
        postsListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func reloadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
        //I think unnecessary?
        /*
         let db = Firestore.firestore()
         let  postsReference =  db.collection("channels")
         
         for post in posts {
         if let id = post.id {
         let postRef = postsReference.document(id)
         postRef.getDocument { (documentSnapshot, err) in
         if let err = err {
         print("Error getting document: \(err)")
         } else {
         
         let docId = documentSnapshot?.documentID
         let commentCount = documentSnapshot?.get("commentCount") as! String
         let commentCountInt = Int(commentCount)!
         print("after reload, comment count: \(commentCountInt)")
         }
         
         }
         }
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
         self.tableView.reloadData()
         self.tableView.refreshControl?.endRefreshing()
         }
         */
    }
    
    private func addPostToTable(_ post: Post) {
        guard !posts.contains(post) else {
            return
        }
        
        posts.append(post)
        posts.sort()
        
        guard let index = posts.index(of: post) else {
            return
        }
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func updatePostInTable(_ post: Post) {
        guard let index = posts.index(of: post) else {
            return
        }
        
        posts[index] = post
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func removePostFromTable(_ post: Post) {
        guard let index = posts.index(of: post) else {
            return
        }
        
        posts.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let post = Post(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            addPostToTable(post)
            
        case .modified:
            updatePostInTable(post)
            
        case .removed:
            removePostFromTable(post)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let currUser = AppController.user!
        uid = currUser.uid
        
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
        
        print("current uid viewdidload: \(uid)")
        
        tableView.delegate = self
        tableView.dataSource = self
        //loadUserHearts()
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadData), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        
        //Trying to retrieve specific post IDs (unsuccessfully)
       /* for postID in joinedChatIDs {
            let postsRef = db.collection("channels").document(postID)
            postsRef.addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                if document.metadata.hasPendingWrites {
                    self.handleDocumentChange(document)
                }
                    let source = document.metadata.hasPendingWrites ? "Local" : "Server"
                    print("\(source) data: \(document.data() ?? [:])")
                }
        }*/
            let postsReference =  db.collection("channels")
            let query = postsReference
                .whereField("isActive", isEqualTo: "true")
    
            postsListener =  query.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        }
    }
    
    // This was the old class we had for this view controller, we can probs delete this all soon
    /*
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
*/
}
