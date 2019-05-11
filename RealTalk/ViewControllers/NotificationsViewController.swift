//
//  NotificationsViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 5/9/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var notifs: [CustomNotif] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notifCell") as! NotificationTableViewCell

        let currNotif = notifs[indexPath.row]

        var notifStr = "\(currNotif.title) \"\(currNotif.body)"

        cell.bodyLabel.text = notifStr
        cell.dateLabel.text = currNotif.timestamp
        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {

        //let manager = PushNotificationManager()
        //manager.getPendingNotifs()
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in

            for notif in notifications {
                print(notif)
                let body = notif.request.content.body
                let timestamp = notif.date
                print("user info:\(notif.request.content.userInfo)")
                let title = notif.request.content.title
                let dateHelper = DateHelper()
                let date = dateHelper.timeAgoSinceDate(date: timestamp as NSDate, numericDates: false)
                print("body: \(body), date: \(date)")


                let notif = CustomNotif(body: body, timestamp: date, type: "heart", title: title)
                self.notifs.append(notif)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }




        }

        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
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
    @IBOutlet weak var onlineIndicator: UIImageView!


}
