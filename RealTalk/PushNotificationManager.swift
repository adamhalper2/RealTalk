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

    func type()->String {
        return self.rawValue
    }
}

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    var userID: String?
    var notifications: [UNNotification]?
    var formatted: CustomNotif?


    init?(userID: String) {
        self.userID = userID
    }

    override init() {
        super.init()
    }

    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
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
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {


        print(response)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }

    func getPendingNotifs() {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            self.notifications = notifications

        }
    }

}

class PushNotificationSender {


    func sendPushNotification(to token: String, title: String, body: String, postID: String) {

        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : postID, "subtitle": body],
                                           "data" : ["test-data": "postID"]
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
