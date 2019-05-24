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
import GoogleMobileAds
import EzPopup


class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate {

    private var votes = [String:[Vote]]()
    private var posts = [Post]()
    private var postsListener: ListenerRegistration?
    //private var votesListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?
    private var heartsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser!
    private let application = UIApplication.shared

    lazy var adBannerView: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = "ca-app-pub-3243429236269107/6069914982"
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        return adBannerView
    }()

    var refreshControl = UIRefreshControl()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heartBtn: UIButton!

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
                        self.notificationButton?.badgeBackgroundColor = UIColor.customPurple2
                        self.notificationButton?.badgeTextColor = UIColor.white
                    }
                    self.notificationButton?.badge = "\(self.unreadNotifCount)"
                }
                application.applicationIconBadgeNumber = unreadNotifCount
            }
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("post count: \(posts.count)")
        return posts.count
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let post = posts[indexPath.row]
        if post.pollID == "" {
            print("post.pollid = empty : \(post.pollID)")
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
            cell.setCell(post: post)
            print("returning post cell")
            return cell
        } else {
            print("post.pollid != empty : \(post.pollID)")
            let cell = tableView.dequeueReusableCell(withIdentifier: "pollCell") as! PollTableViewCell
            if cell.votes.count > 0 {
                print("cell vote count > 0 before setCell")
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
        let userId = user?.uid
        let isPostMember = post.members.contains(userId!)
        let isBanned = post.bannedList.contains(userId!)
        if (!post.isLocked || isPostMember) && !isBanned {
            let vc = ChatViewController(user: user!, post: post)
            self.navigationController?.pushViewController(vc, animated:true)
        } else if post.isLocked {
            // display locked message
        } else if isBanned {
            // display is banned message
        }
    }

    deinit {
        //votesListener?.remove()
        postsListener?.remove()
        notificationsListener?.remove()
        heartsListener?.remove()
    }


    /*
    func loadVotes() {
        print("load votes called")
        let voteRef = db.collection("votes")
        votesListener = voteRef.addSnapshotListener({ (querySnapshot, err) in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(err?.localizedDescription ?? "No error")")
                return
            }
            snapshot.documentChanges.forEach { change in
                print(snapshot)
                guard let vote = Vote(document: change.document) else {
                    print("couldnt create vote from doc")
                    return
                }
                let pollID = vote.pollID
                print("appended poll...post count is \(self.posts.count)")

                var pollVotes = self.votes[pollID] ?? [Vote]()
                pollVotes.append(vote)
                self.votes[pollID] = pollVotes

                for (index, post) in self.posts.enumerated() {
                    if post.pollID == pollID {
                        let indexPath = IndexPath(row: index, section: 1)
                        if let cell = self.tableView.cellForRow(at: indexPath) as? PollTableViewCell {
                            cell.votes = pollVotes
                            print("changing cell votes from home view")
                        }
                    }
                }
            }
        })
    }
    */

    func setTitle(title:String, subtitle:String) -> UIView {

        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height

        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: screenWidth/2, height: 20))
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "DIN Alternate", size: 17)!
        titleLabel.text = title
        titleLabel.lineBreakMode = .byTruncatingTail

        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()

        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 40))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)

        let recognizer = UITapGestureRecognizer(target: self, action:nil)
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(recognizer)

        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width

        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }

        return titleView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        PushNotificationManager.shared.userID = user.uid
        PushNotificationManager.shared.registerForPushNotifications()

        tableView.delegate = self
        tableView.dataSource = self
        setNavBar()
        loadUnreadNotifs()
        loadUserHearts()
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadData), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl

        let postsReference =  db.collection("channels").whereField("isActive", isEqualTo: "true")

        postsListener =  postsReference.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            snapshot.documentChanges.forEach { change in
                self.handlePostDocumentChange(change)
            }
        }
        adBannerView.load(GADRequest())

    }

    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("banner loaded successfully")

        let translateTransform = CGAffineTransform(translationX: 0, y: -bannerView.bounds.size.height)
        bannerView.transform = translateTransform

        UIView.animate(withDuration: 0.5) {
            self.tableView.tableHeaderView?.frame = bannerView.frame
            bannerView.transform = CGAffineTransform.identity
            self.tableView.tableHeaderView = bannerView
        }
    }

    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }



    func setNavBar() {
        //1. customize title font
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "DIN Alternate", size: 25)!]
        //self.navigationItem.titleView = setTitle(title: "Stanford", subtitle: "100 members")


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

        let handleBtn = UIButton()
        handleBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        handleBtn.tintColor = UIColor.black
        handleBtn.setImage(UIImage(named: "profileIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        handleBtn.addTarget(self, action: #selector(changeHandleTapped), for: .touchUpInside)

        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: notificationButton), UIBarButtonItem(customView: handleBtn)]
    }

    @objc func changeHandleTapped() {

        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let handleVC = storyboard.instantiateViewController(withIdentifier: "handleVC") as! ChangeHandleViewController

        let popupVC = PopupViewController(contentController: handleVC, popupWidth: 300, popupHeight: 235)
        popupVC.cornerRadius = 5
        present(popupVC, animated: true, completion: nil)
    }

    /*
     func addBadge(itemvalue: String) {
     let notificationButton = BadgeNotificationButton()
     notificationButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
     notificationButton.tintColor = UIColor.black
     notificationButton.setImage(UIImage(named: "notificationIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
     notificationButton.badgeEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 15)
     notificationButton.badge = itemvalue
     notificationButton.addTarget(self, action: #selector(notifTapped), for: .touchUpInside)
     self.notificationButton = notificationButton
     self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: notificationButton)
     //self.navigationItem.rightBarButtonItem?.customView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(notifTapped)))

     }
     */

    @objc func notifTapped() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let notifVC = storyBoard.instantiateViewController(withIdentifier: "notifVC") as! NotificationsViewController
        //self.present(notifVC, animated: true, completion: nil)
        self.navigationController?.pushViewController(notifVC, animated:true)
    }

    func loadUserHearts() {
        let userRef = db.collection("students").document(user.uid)
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

        let notifRef = db.collection(["students", user.uid, "notifications"].joined(separator: "/")).whereField("read", isEqualTo: "false")
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




    @IBAction func notifBtnTapped(_ sender: Any) {

    }

    @IBAction func heartBtnTapped(_ sender: Any) {

    }



    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        //navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //navigationController?.setNavigationBarHidden(false, animated: animated)
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
        posts.sort() { $0.timestamp > $1.timestamp }


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

    private func handlePostDocumentChange(_ change: DocumentChange) {
        guard let post = Post(document: change.document) else {
            return
        }
        
        if post.bannedList.contains(user.uid) {
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

     /*
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
            let nothingButton = UITableViewRowAction(style: .default, title: "") { (action, indexPath) in
                self.tableView.dataSource?.tableView!(self.tableView, commit: .none, forRowAt: indexPath)
                return
            }
            nothingButton.backgroundColor = UIColor.white
            return [nothingButton]
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        if editingStyle == .delete {
            if post.authorID == AppController.user?.uid {
                deactivateChat(post: post)
                posts.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
  */
    
}
