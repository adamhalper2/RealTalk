//
//  NotificationsViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 5/11/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseFirestore

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let db = Firestore.firestore()
    private var reference: CollectionReference?
    private var notificationListener: ListenerRegistration?
    private var notifications: [CustomNotif] = []


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notifCell") as! NotificationTableViewCell

        let currNotif = notifications[indexPath.row]
        let notifStr = "\(currNotif.title) \"\(currNotif.body)\""

        cell.bodyLabel.text = notifStr

        let dateHelp = DateHelper()
        cell.dateLabel.text = dateHelp.timeAgoSinceDate(date: currNotif.timestamp, numericDates: true)

        let colors = Colors()
        if (!currNotif.read) {
            cell.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
        } else {
            cell.backgroundColor = UIColor.white
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            guard let notifID = notifications[indexPath.row].notifID else {return}
            guard let userID = AppController.user?.uid else {return}
            let notifRef = db.collection(["students", userID, "notifications"].joined(separator: "/")).document(notifID)
            notifRef.delete()
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }

    @IBOutlet weak var tableView: UITableView!


    override func viewDidLoad() {

        //let usersRef = Firestore.firestore().collection("students").document(uid)
        //usersRef.setData(["fcmToken": token], merge: true)

        //let manager = PushNotificationManager()
        //manager.getPendingNotifs()
        /*
         UNUserNotificationCenter.current().getPendingNotificationRequests { (notifications) in
         print("\n\npending notif requests: \(notifications)")
         }
         UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
         for notif in notifications {
         print(notif)
         let body = notif.request.content.body
         guard let categoryID = notif.request.content.categoryIdentifier as? String else {
         print("cateogry ID returned nil")
         return
         }
         let userInfo = notif.request.content.userInfo
         guard let postID = userInfo["gcm.notification.postID"] as? String else {return}
         print("postID: \(postID)")
         print("categoryID: \(categoryID)")
         let timestamp = notif.date
         print("user info:\(notif.request.content.userInfo)")
         let title = notif.request.content.title
         let dateHelper = DateHelper()
         let date = dateHelper.timeAgoSinceDate(date: timestamp as NSDate, numericDates: false)
         print("body: \(body), date: \(date)")
         let notif = CustomNotif(body: body, timestamp: date, type: categoryID, title: title, postID: postID)
         self.notifs.append(notif)
         DispatchQueue.main.async {
         self.tableView.reloadData()
         }
         }
         }
         */

        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        loadNotifications()
        // Do any additional setup after loading the view.
    }

    func loadNotifications() {
        guard let userID = AppController.user?.uid else {return}
        reference = db.collection(["students", userID, "notifications"].joined(separator: "/"))

        notificationListener = reference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        }

    }

    deinit {
        notificationListener?.remove()
    }

    func updateReadStatus(notification: CustomNotif) {
        guard let userID = AppController.user?.uid else {return}
        if reference == nil {
            reference = db.collection(["students", userID, "notifications"].joined(separator: "/"))
        }

        guard let notifID = notification.notifID else {return}
        let read = true
        reference?.document(notifID).updateData([
            "read": String(read)
            ])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let notif = notifications[indexPath.row]
        guard let user = AppController.user else {return}
        updateReadStatus(notification: notif)

        guard let postID = notif.postID else {return}

        let postReference =  db.collection("channels").document(postID)
        postReference.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                guard let post = Post(data: data, docId: documentSnapshot!.documentID) else {return}
                let cell = tableView.cellForRow(at: indexPath)
                cell?.backgroundColor = UIColor.white
                let vc = ChatViewController(user: user, post: post)
                self.navigationController?.pushViewController(vc, animated:true)

                print(post)
            }
        }
    }

    private func addPostToTable(_ notification: CustomNotif) {
        guard !notifications.contains(notification) else {
            return
        }
        notifications.append(notification)
        notifications.sort()

        guard let index = notifications.index(of: notification) else {
            return
        }
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    private func removePostFromTable(_ notification: CustomNotif) {
        guard let index = notifications.index(of: notification) else {
            return
        }

        notifications.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }


    private func handleDocumentChange(_ change: DocumentChange) {
        guard var notification = CustomNotif(document: change.document) else {
            return
        }

        switch change.type {
        case .added:
            addPostToTable(notification)
        case .removed:
            removePostFromTable(notification)
        default:
            print("default called for handle doc change")
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

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    override func prepareForReuse() {
        self.backgroundColor = UIColor.white
    }


}
