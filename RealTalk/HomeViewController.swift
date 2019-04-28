//
//  HomeViewController.swift
//  RealTalk
//
//  Created by Adam Halper on 4/27/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit
import Firebase
import RAMAnimatedTabBarController

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {


    let samplePost1 = Post(content: "I have a crazy roommate. He laminated live goldfish to the kitchen table. When I talked to my other two roommates about the crazy one, there was some general shifting from foot to foot, some half-hearted agreements that the situation was untenable, but a general unwillingness to deal with the situation with the defense I mean, he's our boy", author: "FreddyKeys")
    let samplePost2 = Post(content: "I feel like my major is useless...I wanna switch but I'm worried it's too late. Looking for someone to talk to who has gone through this", author: "ClearEyes")
    let samplePost3 = Post(content: "Can someone who interned at FB/Google/etc tell me what the interview process was like?!", author: "MrBean")
    var samplePosts: [Post]?

    var postArray = [Post]()

    @IBOutlet weak var tableView: UITableView!

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        print("sample posts \(samplePosts!.count)")
        return postArray.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell

        let posts = postArray
        print(posts.count)
        print("nidex path: \(indexPath.section)")
     
        cell.authorLabel.text = posts[indexPath.section].author
        cell.contentLabel.text = posts[indexPath.section].content

        let df = DateFormatter()
        df.dateFormat = "hh" //change to show either day or hour or minute
        cell.timeLabel.text = df.string(from: posts[indexPath.section].date) + "hr"
        cell.commentBtn.titleLabel!.text = "34"

        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        loadPosts()
        samplePosts = [samplePost1, samplePost2, samplePost3]
        tableView.delegate = self
        tableView.dataSource = self


        // Do any additional setup after loading the view.
    }

    func loadPosts(){
        print("load Posts called \n")
        Database.database().reference().child("posts").observe(.childAdded) { (snapshot: DataSnapshot) in
            print("snapshot value:\n \(snapshot.value)")
            if let dict = snapshot.value as? [String: Any] {
                let content = dict["content"] as! String
                let photoUrlString = dict["photoUrl"] as! String
                let userID = dict["userID"] as! String
                let post = Post(content: content, author: userID)
                self.postArray.append(post)

                //let url = URL(string: photoUrlString)
                //let data = try? Data(contentsOf: url!)

                self.tableView.reloadData()
            }
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
