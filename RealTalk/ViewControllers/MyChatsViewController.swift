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
    private var heartsListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?

    private let application = UIApplication.shared
    private let db = Firestore.firestore()
    private var joinedChatIDs: [String]?
    private var uid = ""

    
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!

    var heartButton = UIButton()
    var notificationButton: BadgeButton?
    
    var heartCount : Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.heartButton.setTitle(String(self.heartCount), for: .normal)
            }
        }
    }
    var unreadNotifCount : Int = 0 {
        didSet {
            if notificationButton != nil {
                
                DispatchQueue.main.async {
                    if self.unreadNotifCount == 0 {
                        self.notificationButton?.badgeBackgroundColor = UIColor.clear
                        self.notificationButton?.badgeTextColor = UIColor.clear
                    } else if self.notificationButton?.badgeBackgroundColor == UIColor.clear {
                        self.notificationButton?.badgeBackgroundColor = UIColor.customPurple
                        self.notificationButton?.badgeTextColor = UIColor.white
                    }
                    self.notificationButton?.badge = "\(self.unreadNotifCount)"
                }
                application.applicationIconBadgeNumber = unreadNotifCount
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        if post.pollID == "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as! ChatPreviewTableViewCell
            cell.setCell(post: post)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pollPreviewCell") as! PollPreviewTableViewCell
            if cell.votes.count > 0 {
                cell.resetCell()
            }
            cell.setCell(post: post)
            return cell

        }
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
        let post = posts[indexPath.row]
        if editingStyle == .delete {
            if post.authorID == AppController.user?.uid {
                deactivateChat(post: post)
                posts.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                removeChatToUserList(postId: post.id!)
                removeMember(post: post)
                posts.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    @objc func heartButtonClicked(_ sender: UIButton!) {
        let alertController = UIAlertController(title: "Love Count", message: "This number represents all the love you have received from other users on your posts and messages. Click on any user's chat messages to see their love count and give love, and participate in conversations to increase yours!", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            self.dismiss(animated: true, completion: nil)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let post = posts[indexPath.row]
        if post.authorID == AppController.user?.uid {
            let deleteButton = UITableViewRowAction(style: .default, title: "Delete Chat") { (action, indexPath) in
                self.tableView.dataSource?.tableView!(self.tableView, commit: .delete, forRowAt: indexPath)
                return
            }
            deleteButton.backgroundColor = UIColor.red
            return [deleteButton]
            
        } else {
            let deleteButton = UITableViewRowAction(style: .default, title: "Leave Chat") { (action, indexPath) in
                self.tableView.dataSource?.tableView!(self.tableView, commit: .delete, forRowAt: indexPath)
                return
            }
            deleteButton.backgroundColor = UIColor.black
            return [deleteButton]
        }
    }
    
    func deactivateChat(post: Post) {
        let postRef = db.collection("channels").document(post.id!)
        postRef.updateData([
            "isActive": String(false)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
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
        setNavBar()
        loadUnreadNotifs()
        loadUserHearts()
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setNavBar() {
        //1. customize title font
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "DIN Alternate", size: 25)!]
        
        
        //2. add heart
        let heartButton = UIButton(type: .system)
        heartButton.setImage(UIImage(named: "heartIconSmall"), for: .normal)
        heartButton.setImage(UIImage(named: "heartIconSmall")?.withRenderingMode(.alwaysTemplate), for: .normal)
        heartButton.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
        heartButton.tintColor = UIColor.black
        heartButton.contentHorizontalAlignment = .left
        heartButton.titleEdgeInsets.left = 5
        //heartButton.sizeToFit()
        self.heartButton = heartButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: heartButton)
        
        heartButton.addTarget(self, action: #selector(heartButtonClicked), for: .touchUpInside)
        
        //3. add notifs
        let notificationButton = BadgeButton()
        notificationButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        notificationButton.tintColor = UIColor.black
        notificationButton.setImage(UIImage(named: "notificationIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        notificationButton.badgeEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 15)
        notificationButton.badge = "0"
        
        notificationButton.addTarget(self, action: #selector(notifTapped), for: .touchUpInside)
        self.notificationButton = notificationButton
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: notificationButton)
        
    }
    
    
    @objc func notifTapped() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let notifVC = storyBoard.instantiateViewController(withIdentifier: "notifVC") as! NotificationsViewController
        //self.present(notifVC, animated: true, completion: nil)
        self.navigationController?.pushViewController(notifVC, animated:true)
    }
    
    func loadUserHearts() {
        let user = AppController.user
        let userRef = db.collection("students").document(user!.uid)
        heartsListener = userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            
            if let heartCount = data["heartCount"] as? String {
                if let heartCountInt = Int(heartCount) {
                    self.heartCount = heartCountInt
                }
            }
        }
    }
    
    func loadUnreadNotifs() {
        let user = AppController.user
        let notifRef = db.collection(["students", user!.uid, "notifications"].joined(separator: "/")).whereField("read", isEqualTo: "false")
        notificationsListener = notifRef.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            snapshot.documentChanges.forEach { change in
                self.handleNotifDocumentChange(change)
            }
        }
    }
    
    
    
    private func handleNotifDocumentChange(_ change: DocumentChange) {
        
        switch change.type {
        case .added:
            self.unreadNotifCount += 1
            break
        case .modified:
            break
        case .removed:
            self.unreadNotifCount -= 1
            break
        }
    }

    
    @objc func reloadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func addPostToTable(_ post: Post) {
        guard !posts.contains(post) else {
            return
        }
        
        posts.append(post)
        posts.sort(by: >)
        
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
        posts.sort(by: >)
        let newIndex = posts.index(of: post)!
        tableView.reloadRows(at: [IndexPath(row: newIndex, section: 0), IndexPath(row: index, section: 0)], with: .automatic)
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
        
        if post.bannedList.contains(AppController.user!.uid) {
            switch change.type {
            case .added:
                return
            case .modified:
                removePostFromTable(post)
                
            case .removed:
                removePostFromTable(post)
            }
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
