//
//  MembersListViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 5/16/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol MemberVCDelegate {
    func memberCellTapped()
}

class MembersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MemberCellDelegate {

    func memberCellTapped(userID: String) {
        chatViewRef?.addBannedMember(uid: userID)
        chatViewRef?.removeMember(uid: userID)
        chatViewRef?.removeChatFromUserList(uid: userID)
        pushNotifyBannedUser(bannedID: userID)
        print("removed user")
    }


    var members : [Student] = []
    var post: Post?
    private let db = Firestore.firestore()
    let user = AppController.user!
    var chatViewRef: ChatViewController?


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as! MemberTableViewCell

        let user = members[indexPath.row]
        guard let post = post else {return cell}

        cell.setCell(user: user, post: post)
        return cell

    }

    /*
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return "Members"
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))


        let label = UILabel()
        label.frame = CGRect.init(x: headerView.frame.width/2 - 50, y: 5, width: 100, height: headerView.frame.height-10)
        label.textAlignment = .center
        label.text = "Members (\(members.count))"
        label.font = UIFont(name: "DIN Alternate", size: 18) // my custom font
        label.textColor = .black // my custom colour

        headerView.addSubview(label)

        return headerView
    }

      */



    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var membersLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        if let post = post {
            let memberCount = post.members.count
            if memberCount == 1 {
                membersLabel.text = "Member (\(post.members.count))"
            } else {
                membersLabel.text = "Members (\(post.members.count))"
            }
            loadMembers(memberIds: post.members)
        }

        // Do any additional setup after loading the view.
    }

    func loadMembers(memberIds: [String]) {
        print("member count is \(memberIds.count)")
        for member in memberIds {
            let userRef = db.collection("students").document(member)
            userRef.getDocument { (documentSnapshot, err) in
                guard let snapshot = documentSnapshot else {
                    print("Error listening for channel updates: \(err?.localizedDescription ?? "No error")")
                    return
                }
                guard let data = snapshot.data() else {return}
                if let student = Student(data: data) {
                    print(student)
                    print("added student \(student)")

                    self.members.append(student)
                }

            }

        }
        db.collection("students")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func pushNotifyBannedUser(bannedID: String) {
        db.collection("students").document(bannedID)
            .getDocument { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }

                guard let content = self.post?.content else {return}
                guard let postID = self.post?.id else {return}
                guard let token = data["fcmToken"] as? String else {return}

                let sender = PushNotificationSender()
                sender.sendPushNotification(to: token, title: "You were removed from this chat", body: "\"\(content)\"", postID: postID, type: UserNotifs.remove.type(), userID: bannedID)
                print("banned notif sent")
        }

    }
}
