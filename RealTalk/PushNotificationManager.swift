//
//  PushNotificationManager.swift
//  
//
//  Created by Adam Halper on 5/8/19.
//

import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications


enum UserNotifs: String {
    case heart
    case messageOP
    case messageMembers
    case remove

    func type()->String {
        return self.rawValue
    }
}

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    var userID: String?
    var notifications: [UNNotification]?
    private let db = Firestore.firestore()
    private var reference: CollectionReference?

    private var window: UIWindow!
    private var rootViewController: UIViewController? {
        didSet {
            if let vc = rootViewController {
                window.rootViewController = vc
            }
        }
    }


    static let shared = PushNotificationManager()


    override private init() {
        super.init()
        //dont do anything
    }

    //    private init(userID: String) {
    //        self.userID = userID
    //    }
    //    override init() {
    //        super.init()
    //    }
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (status, err) in
                if (err != nil) {
                    print(err!)
                }
                Analytics.logEvent("requested_push_permission", parameters: [
                    "didAcceptPush": status as NSObject
                    ])
            }

            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        setCategories()
    }

    func updateFirestorePushTokenIfNeeded() {
        guard let uid = userID else {return}
        print("updating push token called")
        if let token = Messaging.messaging().fcmToken {
            let usersRef = Firestore.firestore().collection("students").document(uid)
            usersRef.setData(["fcmToken": token], merge: true)
            print("updating user token")
        }
    }

    func setCategories() {

        let heartCategory =
            UNNotificationCategory(identifier: UserNotifs.heart.type(),
                                   actions: [],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)

        let messageOPCategory =
            UNNotificationCategory(identifier: UserNotifs.messageOP.type(),
                                   actions: [],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)

        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([heartCategory, messageOPCategory])
    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("remote message is \(remoteMessage.appData)")

    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        updateFirestorePushTokenIfNeeded()
    }

    func updateReadStatus(notifID: String) {
        let db = Firestore.firestore()
        var reference: CollectionReference?
        guard let userID = AppController.user?.uid else {return}
        if reference == nil {
            reference = db.collection(["students", userID, "notifications"].joined(separator: "/"))
        }

        let read = String(true)
        reference?.document(notifID).updateData([
            "read": String(read)
            ])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("did receive notif")
        let notification = response.notification
        let userInfo = notification.request.content.userInfo
        guard let notifID = userInfo["gcm.notification.notifID"] as? String else {return}
        updateReadStatus(notifID: notifID)
        print(response)

        let rootViewController =  UIApplication.shared.keyWindow?.rootViewController as! UITabBarController

        guard let user = Auth.auth().currentUser else {return}
        guard let postID = userInfo["gcm.notification.postID"] as? String else {return}

        let postRef = db.collection("channels").document(postID)
        postRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                guard let post = Post(data: data, docId: postID) else {return}
                let navController = rootViewController.selectedViewController as? UINavigationController
                let vc = ChatViewController(user: user, post: post)
                navController!.pushViewController(vc, animated:true)
            }
        }
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("will present called")

        /*
         let body = notification.request.content.body
         let title = notification.request.content.title
         let type = notification.request.content.categoryIdentifier
         let timestamp = notification.date
         let userInfo = notification.request.content.userInfo
         guard let postID = userInfo["gcm.notification.postID"] as? String else {return}
         let notif = CustomNotif(body: body, timestamp: timestamp as NSDate, type: type, title: title, postID: postID, read: true)
         save(notif)
         print(notification.request.content)
         */
        completionHandler([.alert, .badge, .sound])
    }
}

class PushNotificationSender {

    private let db = Firestore.firestore()
    private var reference: CollectionReference?

    private func save(_ notif: CustomNotif, userID: String) {

        reference = db.collection(["students", userID, "notifications"].joined(separator: "/"))

        guard let notifID = notif.notifID else {return}
        reference?.document(notifID).setData(notif.representation) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
        }
    }


    func sendPushNotification(to token: String, title: String, body: String, postID: String, type: String, userID: String) {

        let body = body
        let title = title
        let type = type
        let timestamp = NSDate()
        let postID = postID
        let notifID = UUID().uuidString

        let notif = CustomNotif(body: body, timestamp: timestamp, type: type, title: title, postID: postID, read: false, notifID: notifID)
        self.save(notif, userID: userID)

        UNUserNotificationCenter.current().requestAuthorization(options: .badge)
        { (granted, error) in
            if error != nil {
                UIApplication.shared.applicationIconBadgeNumber = 1
            }
        }


        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "click-action": type, "postID": postID, "notifID": notifID],
                                           "userInfo" : [],
                                           "badge" :  1
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAwt24TG8:APA91bHO__B_OkaFM1nYAVM54lk7Lk1C5mLxXYFux2wZ1UOoRtduUauGkMeCCdsK7hU9e6AqCkBrCW5ZMMvQ1BXk68wFPk4UUkOIKvCnnfsrtZi8tm8uDux9EQbaaULAQ6oZdTcSn4oQ", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
