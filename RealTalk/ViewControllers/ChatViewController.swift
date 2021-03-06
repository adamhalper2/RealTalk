/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase
import MessageKit
import FirebaseFirestore
import Photos
import EzPopup


private let db = Firestore.firestore()
private var reference: CollectionReference?

/*
struct AvatarObj {

    let senderID: String
    var avatarView: AvatarView
    var message: MessageType

    init(senderID: String, avatarView: AvatarView, message: MessageType) {
        self.senderID = senderID
        self.avatarView = avatarView
        self.message = message
    }
}
*/

final class ChatViewController: MessagesViewController {

  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  private var membersListener: ListenerRegistration?

  var members: [Student] = []
  
  private let user: User
  private var post: Post
  
  private var isSendingPhoto = false {
    didSet {
      DispatchQueue.main.async {
        self.messageInputBar.leftStackViewItems.forEach { item in
          item.isEnabled = !self.isSendingPhoto
        }
      }
    }
  }

  //var messageIndexes : [IndexPath: AvatarObj] = [:]
  private let storage = Storage.storage().reference()
  private var lockButton: UIBarButtonItem?
  private var lockUIbtn = UIButton()
  private var isLocked: Bool?
  
  init(user: User, post: Post) {
    self.user = user
    self.post = post
    super.init(nibName: nil, bundle: nil)
    title = post.content
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    messageListener?.remove()
    membersListener?.remove()
  }

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
        //titleLabel.sizeToFit()


        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()

        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 40))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
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

    @objc func titleTapped() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let membersVC = storyboard.instantiateViewController(withIdentifier: "membersVC") as! MembersListViewController
        membersVC.post = post
        membersVC.chatViewRef = self

        let popupVC = PopupViewController(contentController: membersVC, popupWidth: 300, popupHeight: 400)
        popupVC.cornerRadius = 5
        present(popupVC, animated: true, completion: nil)

        //self.navigationController?.present(membersVC, animated: true)

    }

    /*
    func loadMembers(memberIds: [String]) {
        let postMembers = post.members
        let memberRef = db.collection("students").addSnapshotListener { (querySnap, err) in
            guard let snapshot = querySnap else {
                print("Error listening for member updates: \(err?.localizedDescription ?? "No error")")
                return
            }

            snapshot.documentChanges.forEach { change in
                if let student = Student(document: change.document) {
                    if postMembers.contains(student.uid) {
                        for (index, avatar) in self.messageIndexes {
                            if avatar.senderID == student.uid {
                                print("setting avatar view")
                                self.configureAvatarView(avatar.avatarView, for: avatar.message, at: index, in: self.messagesCollectionView)
                            }
                        }

                        /*
                        for (index, member) in self.members.enumerated() {
                            if member.uid == student.uid {
                                self.members[index] = student
                                print("updated member from \(member) to \(student)")
                            } else {
                                self.members.append(student)
                            }
                        }
                        print("members count \(self.members.count)")
                        */
                    }
                }
            }
        }
    }
    */


  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.titleView = setTitle(title: "\(post.content)", subtitle: "\(post.members.count) members")

    //loadMembers(memberIds: post.members)

    self.tabBarController?.tabBar.isHidden = true

    guard let id = post.id else {
      navigationController?.popViewController(animated: true)
      return
    }

    reference = db.collection(["channels", id, "thread"].joined(separator: "/"))
    
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
    
    
    db.collection("channels").document(post.id!)
        .addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            
            
            DispatchQueue.main.async {
                self.handlePostChange(data: data, docId: document.documentID)
            }
    }
    
    
//    // 1
    let cameraItem = InputBarButtonItem(type: .system)
    cameraItem.tintColor = .primary
    cameraItem.image = #imageLiteral(resourceName: "camera")

    // 2
    cameraItem.addTarget(
      self,
      action: #selector(cameraButtonPressed),
    for: .primaryActionTriggered
    )
    cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
    messageInputBar.leftStackView.alignment = .center
   messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
//
//    // 3
    messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    
    navigationItem.largeTitleDisplayMode = .never
    
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)

    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    messagesCollectionView.messageCellDelegate = self

    
    if self.post.authorID == self.user.uid {
        isLocked = post.isLocked

        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "padlock-unlock"), for: .normal)
        btn.addTarget(self, action: #selector(toggleChatLock), for: .touchUpInside)
        btn.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        lockButton = UIBarButtonItem(customView: btn)
        if post.isLocked {
            btn.setImage(UIImage(named: "padlock"), for: .normal)
        }
        self.lockUIbtn = btn
        self.navigationItem.rightBarButtonItem = lockButton
    
    }

  }
  
  // MARK: - Actions
  @objc private func toggleChatLock() {
        if self.isLocked! {
            lockUIbtn.setImage(UIImage(named: "padlock-unlock"), for: .normal)
            self.isLocked = false
        } else {
            lockUIbtn.setImage(UIImage(named: "padlock"), for: .normal)
            self.isLocked = true
        }
    
        let postRef = db.collection("channels").document(post.id!)
        postRef.updateData([
            "isLocked": String(self.isLocked!)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
  }
    
  @objc private func cameraButtonPressed() {
    let picker = UIImagePickerController()
    picker.delegate = self
    
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      picker.sourceType = .photoLibrary
    } else {
      picker.sourceType = .camera
    }
    
    present(picker, animated: true, completion: nil)
  }
  
  // MARK: - Helpers
  
  private func uploadImage(_ image: UIImage, to post: Post, completion: @escaping (URL?, Error?) -> Void) {
    guard let channelID = post.id else {
        completion(nil, nil)
      return
    }
    
    guard let scaledImage = image.scaledToSafeUploadSize,
      let data = scaledImage.jpegData(compressionQuality: 0.4) else {
        completion(nil, nil)
        return
    }
    
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    
    let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
    storage.child(channelID).child(imageName).putData(data, metadata: metadata) { meta, error in
 
     // completion(meta?.downloadURL())
        //completion(meta?.path)
        if let path = meta?.path {
            self.getDownloadURL(from: path, completion: completion)
        }
    }
  }
    
    private func getDownloadURL(from path: String, completion: @escaping (URL?, Error?) -> Void) {
        
        self.storage.child(path).downloadURL(completion: completion)
    }
  
  private func sendPhoto(_ image: UIImage) {
    isSendingPhoto = true
    
    uploadImage(image, to: post) { [weak self] url,err  in
      guard let `self` = self else {
        return
      }
      self.isSendingPhoto = false
      
      guard let url = url else {
        return
      }
      
      var message = Message(user: self.user, image: image)
      message.downloadURL = url
      
      self.save(message)
      self.messagesCollectionView.scrollToBottom()
    }
  }

  
    private func save(_ message: Message) {
        reference?.addDocument(data: message.representation) { error in
          if let e = error {
            print("Error sending message: \(e.localizedDescription)")
            return
          }

          self.messagesCollectionView.scrollToBottom()
        }
        let delta = 1
        updateCommentCount(delta: delta)
        if let toID = post.authorID {
            if toID == user.uid {return}
            pushNotifyComment(toID: toID)
        }
    }

    func pushNotifyComment(toID: String) {
        pushAuthor(toID: toID)
        pushMembers(authorID: toID)
    }

    func pushMembers(authorID: String) {
        guard let postID = post.id else {return}
        for member in post.members {
            if member == authorID {
                print("\n continuing")
                continue
            }
            db.collection("students").document(member)
                .getDocument { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else {
                        print("Document data was empty.")
                        return
                    }
                    guard let token = data["fcmToken"] as? String else {return}
                    guard let username = data["username"] as? String else {return}

                    let sender = PushNotificationSender()
                    guard let displayName = AppSettings.displayName else {return}
                    sender.sendPushNotification(to: token, title: "\(displayName) sent a message", body: "in \"\(self.post.content)\"", postID: postID, type: UserNotifs.messageMembers.type(), userID: member)
                    print("notif sent to \(username)")
            }
        }


    }
    func pushAuthor(toID: String) {
        guard let postID = post.id else {return}
        db.collection("students").document(toID)
            .getDocument { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                guard let token = data["fcmToken"] as? String else {return}
                let sender = PushNotificationSender()
                guard let displayName = AppSettings.displayName else {return}
                sender.sendPushNotification(to: token, title: "\(displayName) sent a message in your chat", body: "\"\(self.post.content)\"", postID: postID, type: UserNotifs.messageOP.type(), userID: toID)
                print("notif sent")
        }
    }

    func updateCommentCount(delta: Int) {
        let newCount = post.commentCount + delta
        guard let id = post.id else { return }
        let postRef = db.collection("channels").document(id)
        postRef.updateData([
            "commentCount": String(newCount)
        ]) { err in
            if let err = err {
                print("Error updating comment count: \(err)")
            } else {
                print("updated comment count to \(newCount)")
            }
        }
    }

  private func insertNewMessage(_ message: Message) {
    guard !messages.contains(message) else {
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.index(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
    
    private func updateMessage(_ message: Message) {

        guard let index = messages.index(of: message) else {
            return
        }
        
        messages[index] = message
        
        messagesCollectionView.reloadData()
    }
    
    private func handlePostChange(data: [String: Any], docId: String) {
    
    guard let post = Post(data: data, docId: docId) else {
        return
    }
    
    
    self.post = post
    
    if post.bannedList.contains(user.uid) {
        _ = navigationController?.popViewController(animated: true)
    }
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard var message = Message(document: change.document) else {
      return
    }
    
    switch change.type {
    case .added:
      if let url = message.downloadURL {
        downloadImage(at: url) { [weak self] image in
          guard let self = self else {
            return
          }
          guard let image = image else {
            return
          }
          
          message.image = image
          self.insertNewMessage(message)
        }
      } else {
        insertNewMessage(message)
      }
    case .modified:
        updateMessage(message)
        
        
    default:
      break
    }
  }
  
  private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
    let ref = Storage.storage().reference(forURL: url.absoluteString)
    let megaByte = Int64(1 * 1024 * 1024)
    
    ref.getData(maxSize: megaByte) { data, error in
      guard let imageData = data else {
        completion(nil)
        return
      }

      completion(UIImage(data: imageData))
    }
  }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else { return }
        let messageType = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        
        let message = messages.first(where: {$0.id == messageType.messageId})
        if message?.sender.id == user.uid { return }
        if post.bannedList.contains((message?.sender.id)!) { return }
        let messageDetailVC = MessageDetailViewController.instantiate()
        messageDetailVC?.isOwner = (post.authorID == user.uid)
        messageDetailVC?.message = message
        messageDetailVC?.chatViewRef = self
        messageDetailVC?.post = self.post
        
        let popupVC = PopupViewController(contentController: messageDetailVC!, popupWidth: 300, popupHeight: 400)
        popupVC.cornerRadius = 5
        present(popupVC, animated: true, completion: nil)
        
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                       in messagesCollectionView: MessagesCollectionView) -> UIColor {
    
    // 1
    return isFromCurrentSender(message: message) ? .primary : .incomingMessage
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                           in messagesCollectionView: MessagesCollectionView) -> Bool {
    
    // 2
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    // 3

    return .bubbleTail(corner, .curved)
  }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath,
                  in messagesCollectionView: MessagesCollectionView) -> CGSize {

    // 1


    let sender = message.sender.id
    print("sender: \(sender) post author: \(post.authorID)")

    if sender == post.authorID {
        return CGSize(width: 13, height: 13)
    } else {
        return CGSize(width: 20, height: 20)
    }
  }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        let sender = message.sender.id
        //let avatar = AvatarObj(senderID: sender, avatarView: avatarView, message: message)
        //messageIndexes[indexPath] = avatar

        print("sender: \(message.sender.displayName) post author: \(post.authorID)")

        if sender == post.authorID {


            let image = UIImage(named: "crownIcon")
            let av = Avatar(image: image, initials: "")
            avatarView.set(avatar: av)
            avatarView.clipsToBounds = false
            avatarView.tintColor = UIColor.customPurple.withAlphaComponent(0.5)
            avatarView.backgroundColor = UIColor.clear
            print("set av author")
        } else {
            let image = UIImage(named: "memberAvatar")
            let av = Avatar(image: image, initials: "")
            
            avatarView.set(avatar: av)
            avatarView.clipsToBounds = false
            avatarView.backgroundColor = UIColor.clear
            avatarView.tintColor = UIColor.darkGray.withAlphaComponent(0.5)
            print("memberCount at avatar is \(members.count)")

            for member in members {
                if member.uid == sender {
                    if member.isOnline {
                        print("setting tint color to green")
                        avatarView.tintColor = UIColor.customGreen.withAlphaComponent(0.5)
                        return
                    }
                }
            }
        }
    }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> CGSize {
    
    // 2
    return CGSize(width: 0, height: 8)
  }

  func heightForLocation(message: MessageType, at indexPath: IndexPath,
                         with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    // 3
    return 0
  }


}

// MARK: - MessagesDataSource



extension ChatViewController: MessagesDataSource {
  
  // 1
  func currentSender() -> Sender {
    return Sender(id: user.uid, displayName: AppSettings.displayName)
  }
  
  // 2
  func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  // 3
  func messageForItem(at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageType {
    
    return messages[indexPath.section]
  }
    
    
  // 4
  func cellTopLabelAttributedText(for message: MessageType,
                                  at indexPath: IndexPath) -> NSAttributedString? {
    
    let name = message.sender.displayName
    return NSAttributedString(
      string: name,
      attributes: [
        .font: UIFont.preferredFont(forTextStyle: .caption1),
        .foregroundColor: UIColor(white: 0.3, alpha: 1)
      ]
    )
  }
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    
    // 1
    let message = Message(user: user, content: text)
    
    // 2
    save(message)

    print("members are: \(post.members)")
    // 2.5 add new member
    addPostUpdate(uid: user.uid, message: message)
    addMember(uid: user.uid)
    addChatToUserList()

    // 3
    inputBar.inputTextView.text = ""
  }

    func addChatToUserList() {
        let userRef = db.collection("students").document(user.uid)
        
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if var joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    print("*~*~old joined chats: \(joinedChatIDsStr)")
                    
                    var joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                    if (!joinedChatIDs.contains(self.post.id!)) {
                        joinedChatIDs.append(self.post.id!)
                    }
                    joinedChatIDsStr = joinedChatIDs.joined(separator: "-")
                    userRef.updateData(
                        ["joinedChatIDs": joinedChatIDsStr]
                    )
                    print("*~*~updated joined chats to \(joinedChatIDsStr)")
                }
            }
        }
    }
    
    func addPostUpdate(uid: String, message: Message) {
        let postRef = db.collection("channels").document(post.id!)

        postRef.updateData([
            "lastMessage": message.content!,
            "updateTimestamp": message.sentDate.toString(dateFormat: "MM/dd/yy hh:mm:ss a ZZ")
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("added member")
            }
        }
    }
    
    func addMember(uid: String) {
        let postRef = db.collection("channels").document(post.id!)
        var mem = post.members
        if post.members.contains(uid) {
            print("Already contains userID")
            return
        }

        mem.append(uid)
        let membersStr = mem.joined(separator: "-")
        postRef.updateData([
            "members": membersStr
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("added member")
                guard let postID = self.post.id else {return}

                Analytics.logEvent("joined_chat", parameters: [
                    "user": self.user.uid as NSObject,
                    "postID": postID as NSObject
                    ])
            }
        }
    }

    func removeMember(uid: String) {
        let postRef = db.collection("channels").document(post.id!)
        var mem = post.members
        if !post.members.contains(uid) {
            print("Doesn't contain userID")
            return
        }
        mem.removeAll{$0 == uid}
        let membersStr = mem.joined(separator: "-")
        postRef.updateData([
            "members": membersStr
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("removed member")
                guard let postID = self.post.id else {return}

                Analytics.logEvent("user_removed", parameters: [
                    "removed_user": uid as NSObject,
                    "postID": postID as NSObject
                    ])
            }
        }
    }



    func removeChatFromUserList(uid: String) {
        let userRef = db.collection("students").document(uid)
        
        userRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else {
                guard let data = documentSnapshot?.data() else {return}
                if var joinedChatIDsStr = data["joinedChatIDs"] as? String {
                    print("*~*~old joined chats: \(joinedChatIDsStr)")
                    
                    var joinedChatIDs = joinedChatIDsStr.components(separatedBy: "-")
                    joinedChatIDs.removeAll{$0 == self.post.id!}
                    joinedChatIDsStr = joinedChatIDs.joined(separator: "-")
                    userRef.updateData(
                        ["joinedChatIDs": joinedChatIDsStr]
                    )
                    print("*~*~updated joined chats to \(joinedChatIDsStr)")
                }
            }
        }
    }
    
    
    func addBannedMember(uid: String) {
        let postRef = db.collection("channels").document(post.id!)
        var banned = post.bannedList
        if post.bannedList.contains(uid) {
            print("Already contains userID")
            return
        }
        banned.append(uid)
        let bannedStr = banned.joined(separator: "-")
        postRef.updateData([
            "bannedList": bannedStr
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("added to banned list")
            }
        }
        for message in messages {
            if message.sender.id == uid {
                let messageRef = db.collection(["channels", post.id!, "thread"].joined(separator: "/")).document(message.id!)
                messageRef.updateData([
                    "content": "User Removed"
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Removed message")
                    }
                }
            }
        }
        
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    
    // 1
    if let asset = info[.phAsset] as? PHAsset {
      let size = CGSize(width: 500, height: 500)
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: size,
        contentMode: .aspectFit,
        options: nil) { result, info in
          
          guard let image = result else {
            return
          }
          
          self.sendPhoto(image)
      }
      
      // 2
    } else if let image = info[.originalImage] as? UIImage {
      sendPhoto(image)
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
  
}
