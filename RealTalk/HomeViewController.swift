//
//  HomeViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {


    var postArray = [Post]()

    @IBOutlet weak var tableView: UITableView!

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return postArray.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell

        let posts = postArray
        print(posts.count)
        print("index path: \(indexPath.section)")
     
        cell.authorLabel.text = posts[indexPath.section].author
        cell.contentLabel.text = posts[indexPath.section].content
        let date = posts[indexPath.section].timestamp
        let timestamp = timeAgoSinceDate(date: date, numericDates: true)
        cell.timeLabel.text = timestamp

        cell.commentBtn.titleLabel!.text = "34"
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }

    /*
    override func viewWillAppear(_ animated: Bool) {
        db.collection("posts")
            .addSnapshotListener { querySnapshot, error in
                if let err = error {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let photoUrlString = document.data()["photo"] as! String
                        let content = document.data()["content"] as! String
                        let userID = document.data()["userID"] as! String
                        let timeString = document.data()["timestamp"] as! String
                        if let timeNum = Double(timeString) {
                            let date = NSDate(timeIntervalSince1970: timeNum)
                            let post = Post(content: content, author: userID, timestamp: date)
                            self.postArray.append(post)
                        }
                        print("\(document.documentID) => \(document.data())")
                    }
                    self.tableView.reloadData()
                }

        }
    }

 */
    override func viewDidLoad() {

        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadPosts()
        tableView.reloadData()

        // Do any additional setup after loading the view.
    }

    func loadPosts(){

        let db = Firestore.firestore()

        let postRef = db.collection("posts")
        postRef.order(by: "timestamp", descending: true).limit(to: 20).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let photoUrlString = document.data()["photo"] as! String
                    let content = document.data()["content"] as! String
                    let userID = document.data()["userID"] as! String
                    let timeString = document.data()["timestamp"] as! String
                    if let timeNum = Double(timeString) {
                        let date = NSDate(timeIntervalSince1970: timeNum)
                        let post = Post(content: content, author: userID, timestamp: date)
                        self.postArray.append(post)
                    }
                    print("\(document.documentID) => \(document.data())")
                }
                self.tableView.reloadData()
            }
        }

    }

     /*
    func loadPosts(){
        print("load Posts called \n")
        Database.database().reference().child("posts").observe(.childAdded) { (snapshot: DataSnapshot) in
            print("snapshot value:\n \(snapshot.value)")
            if let dict = snapshot.value as? [String: Any] {
                let content = dict["content"] as! String
                let photoUrlString = dict["photoUrl"] as! String
                let userID = dict["userID"] as! String
                let timeString = dict["date"] as! String

                if let timeNum = Double(timeString) {
                    let date = NSDate(timeIntervalSince1970: timeNum)
                    let post = Post(content: content, author: userID, timestamp: date)
                    self.postArray.append(post)
                }

                //let url = URL(string: photoUrlString)
                //let data = try? Data(contentsOf: url!)
                //self.postArray = self.postArray.reversed()
                self.tableView.reloadData()
            }
        }
    }
    */
    
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
            return "\(components.minute!) min"
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
