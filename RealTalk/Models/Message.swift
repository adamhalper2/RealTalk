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

import Firebase
import MessageKit
import FirebaseFirestore

struct Message: MessageType {

    let id: String?
    let content: String?
    let sentDate: Date
    let sender: Sender
    var reportCount: Int
    var isActive: Bool

    var data: MessageData {
        if let image = image {
            return .photo(image)
        } else {
            return .text(content!)
        }
    }

    var messageId: String {
        return id ?? UUID().uuidString
    }

    var image: UIImage? = nil
    var downloadURL: URL? = nil

    init(user: User, content: String) {
        sender = Sender(id: user.uid, displayName: AppSettings.displayName)
        self.content = content
        sentDate = Date()
        id = nil
        reportCount = 0
        isActive = true
    }


    init(user: User, image: UIImage) {
        sender = Sender(id: user.uid, displayName: AppSettings.displayName)
        self.image = image
        content = ""
        sentDate = Date()
        id = nil
        isActive = true
        reportCount = 0
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        //    guard let sentDate = data["created"] as? Date else {
        //      return nil
        //    }

        guard let reportCount = data["reportCount"] as? String else {
            return nil
        }
        let reportCountInt = Int(reportCount)!

        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderName = data["senderName"] as? String else {
            return nil
        }

        guard let active = data["isActive"] as? String else {
            return nil
        }
        guard let isActiveBool = Bool(active) else {return nil}

        guard let date = data["created"] as? String else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy hh:mm:ss a ZZ"
        
        var sentDate = Date()
        if let realDate = dateFormatter.date(from: date) {
            sentDate = realDate
        }
        
        id = document.documentID
        self.isActive = isActiveBool

        self.reportCount = reportCountInt

        self.sentDate = sentDate
        sender = Sender(id: senderID, displayName: senderName)

        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
        } else {
            return nil
        }
    }

}

extension Message: DatabaseRepresentation {
    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate.toString(dateFormat: "MM/dd/yy hh:mm:ss a ZZ"),
            "senderID": sender.id,
            "senderName": sender.displayName,
            "reportCount": String(reportCount),
            "isActive": String(isActive)

        ]

        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }

        return rep
    }

}

extension Message: Comparable {

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }

}
