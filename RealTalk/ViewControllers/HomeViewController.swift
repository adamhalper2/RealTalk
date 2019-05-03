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

    var refreshControl = UIRefreshControl()

    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        print("post coount: \(posts.count)")
        
        let post = posts[indexPath.row]
        //cell.authorLabel.text = post.author
        let memberLabel = getMembers(members: post.members, author: post.author)
        cell.authorLabel.text = memberLabel
        print("at click, members: \(post.members). current uid: \(AppController.user!.uid)")

        cell.contentLabel.text = posts[indexPath.row].content
        let date = posts[indexPath.row].timestamp
        let timestamp = timeAgoSinceDate(date: date, numericDates: true)
        cell.timeLabel.text = timestamp

        cell.commentBtn.titleLabel!.text = "34"
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
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


    func getMembers(members: [String], author: String)->String? {
        print("members: \(members), author: \(author)")
        let db = Firestore.firestore()
        var memberLabel = author
        if members.count > 2 {
            memberLabel = author + "and \(members.count - 1) others in chat"
            return memberLabel
        } else if members.count > 1 {
            for member in members {
                let studentRef = db.collection("students").document(member)
                studentRef.getDocument { (documentSnapshot, err) in
                    guard let snapshot = documentSnapshot else {
                        print("Unable to find user for user id \(member): \(err?.localizedDescription ?? "No error")")
                        return
                    }
                    if snapshot.exists {
                        if let data = snapshot.data() {
                            guard let otherAuthor = data["username"] as? String else {
                                return
                            }
                            memberLabel = author + "and \(otherAuthor) in chat"

                        }
                    } else {
                        print("no se existe")
                    }
                    /*
                    if let student = Student(document: snapshot as? QueryDocumentSnapshot) {
                        if student.username != author {
                            memberLabel = author + "and \(student.username) in chat"
                        }
                    }
                    */
                }
            }
        }
        return memberLabel
    }

    deinit {
        postsListener?.remove()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()



        tableView.delegate = self
        tableView.dataSource = self

        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadData), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl

        let db = Firestore.firestore()
        let  postsReference =  db.collection("channels")

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

//    func loadPosts(){
//        print("load Posts called \n")
//        Database.database().reference().child("posts").observe(.childAdded) { (snapshot: DataSnapshot) in
//            print("snapshot value:\n \(snapshot.value)")
//            if let dict = snapshot.value as? [String: Any] {
//                let content = dict["content"] as! String
//                let photoUrlString = dict["photoUrl"] as! String
//                let userID = dict["userID"] as! String
//                let timeString = dict["date"] as! String
//
//                if let timeNum = Double(timeString) {
//                    let date = NSDate(timeIntervalSince1970: timeNum)
//                    let post = Post(content: content, author: userID, timestamp: date)
//                    self.postArray.append(post)
//                }
//
//                //let url = URL(string: photoUrlString)
//                //let data = try? Data(contentsOf: url!)
//                //self.postArray = self.postArray.reversed()
//                self.tableView.reloadData()
//            }
//        }
//    }


    /*
    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = NSDate()
        let earliest = now.earlierDate(date as Date)
        let latest = (earliest == now as Date) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)

        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) mins ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 min ago"
            } else {
                return "A min ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) secs ago"
        } else {
            return "Just now"
        }

    }
    */

    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = NSDate()
        let earliest = now.earlierDate(date as Date)
        let latest = (earliest == now as Date) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)
        print("date is \(date)")
        if (components.year! >= 2) {
            return "\(components.year!)y"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 yr"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!)mo"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!)w"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1w"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!)d"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1d"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!)h"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1h"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!)min"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 min ago"
            } else {
                return "A min ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!)s"
        } else {
            return "Just now"
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
