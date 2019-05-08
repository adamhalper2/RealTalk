//
//  HomeViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var posts = [Post]()
    private var postsListener: ListenerRegistration?
    private let db = Firestore.firestore()

    var refreshControl = UIRefreshControl()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heartBtn: UIButton!
    
    var heartCount = 0

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        let post = posts[indexPath.row]
        cell.setCell(post: post)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let user = AppController.user
        let userId = user?.uid
        if !post.isLocked || (post.members.contains(userId!)) {
            let vc = ChatViewController(user: user!, post: post)
            self.navigationController?.pushViewController(vc, animated:true)
        } else if post.isLocked {
            // display locked message
        }
    }

    deinit {
        postsListener?.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadUserHearts()
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadData), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl

        let  postsReference =  db.collection("channels").whereField("isActive", isEqualTo: "true")


        postsListener =  postsReference.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        }
    }

    func loadUserHearts() {
        guard let currUser = Auth.auth().currentUser else {return}
        let userID = currUser.uid

        db.collection("students").document(userID)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                if let heartCount = data["heartCount"] as? String {
                    print("updated heart count \(heartCount)")
                    //animation?
                    DispatchQueue.main.async {
                        self.heartBtn.setTitle(String(heartCount), for: .normal)
                    }

                }
        }
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

}
