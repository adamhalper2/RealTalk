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
    private var joinedChatIDs: [String]?
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
        let vc = ChatViewController(user: user!, post: post)
        self.navigationController?.pushViewController(vc, animated:true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let post = posts[indexPath.row]
            removeChatToUserList(postId: post.id!)
            removeMember(post: post)
            posts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func removeMember(post: Post) {
        let uid = AppController.user?.uid
        let postRef = db.collection("channels").document(post.id!)
        var mem = post.members
        if !post.members.contains(uid!) {
            print("Doesn't contain userID")
            return
        }
        mem.removeAll{$0 == uid}
        let membersStr = mem.joined(separator: "-")
        postRef.updateData([
            "members": membersStr
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("removed member")
            }
        }
    }
    
    func removeChatToUserList(postId: String) {
        let user = AppController.user
        let userRef = db.collection("students").document(user!.uid)
        
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if var joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    print("*~*~old joined chats: \(joinedChatIDsStr)")
                    
                    var joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                    joinedChatIDs.removeAll{$0 == postId}
                    joinedChatIDsStr = joinedChatIDs.joined(separator: "-")
                    userRef.updateData(
                        ["joinedChatIDs": joinedChatIDsStr]
                    )
                    print("*~*~updated joined chats to \(joinedChatIDsStr)")
                }
            }
        }
    }
    
    deinit {
        postsListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tap)
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
    
    @objc func dismissKeyboard() {
        self.searchBar.endEditing(true)
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
    
    private func handleDocumentChange2(data: [String: Any], id: String) {
        guard let post = Post(data: data, docId: id) else {
            return
        }
        print(id)
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
                    self.addChatListeners()
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
        
        }
    
    private func addChatListeners() {
        let postsReference =  self.db.collection("channels").whereField("isActive", isEqualTo: "true")
        for postID in self.joinedChatIDs! {
            if postID == "" { continue }
            postsReference.whereField(Firebase.FieldPath.documentID(), isEqualTo: postID)
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                        return
                    }

                    snapshot.documentChanges.forEach { change in
                        self.handleDocumentChange(change)
                    }
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
