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


import FirebaseFirestore
import FirebaseAuth

struct Post {
  
  let id: String?
  let authorID: String?
  let author: String
  let content: String
  let timestamp: NSDate
  var commentCount: Int
  var heartCount: Int
  var reportCount: Int
  var members: [String]
  var isActive: Bool
  var isLocked: Bool

  
    init(content: String, author: String, timestamp: NSDate, authorID: String) {
        id = nil
        self.content = content
        self.author = author
        self.timestamp = timestamp
        self.commentCount = 0
        self.heartCount = 0
        self.reportCount = 0
        self.members = [authorID]
        self.authorID = authorID
        self.isActive = true
        self.isLocked = false
    }
  
  init?(document: QueryDocumentSnapshot) {
    let data = document.data()
    
    
    guard let content = data["content"] as? String else {
        return nil
    }

    guard let author = data["author"] as? String else {
        return nil
    }
    
    guard let timestamp = data["timestamp"] as? String else {
        return nil
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yy h:mm a Z"
    
    let date = dateFormatter.date(from: timestamp)! as NSDate

    guard let authorID = data["authorID"] as? String else {
        return nil
    }

    guard let membersStr = data["members"] as? String else {
        return nil
    }
    let members = membersStr.components(separatedBy: "-")

    guard let commentCount = data["commentCount"] as? String else {
        return nil
    }
    let commentCountInt = Int(commentCount)!


    guard let heartCount = data["heartCount"] as? String else {
        return nil
    }
    let heartCountInt = Int(heartCount)!

    guard let reportCount = data["reportCount"] as? String else {
        return nil
    }
    let reportCountInt = Int(reportCount)!

    guard let active = data["isActive"] as? String else {
        return nil
    }

    guard let isActiveBool = Bool(active) else {return nil}
    
    guard let isLocked = data["isLocked"] as? String else {
        return nil
    }
    
    guard let isLockedBool = Bool(isLocked) else {
        return nil
    }
    
    id = document.documentID
    
    self.content = content
    self.author = author
    self.commentCount = commentCountInt
    self.heartCount = heartCountInt
    self.reportCount = reportCountInt
    self.timestamp = date
    self.members = members
    self.authorID = authorID
    self.isActive = isActiveBool
    self.isLocked = isLockedBool
  }
}

extension Post : DatabaseRepresentation {

  
  var representation: [String : Any] {
    var rep = ["content": content]
    rep["author"] = author
    rep["timestamp"] = timestamp.toString(dateFormat: "MM/dd/yy h:mm a Z")
    rep["commentCount"] = String(commentCount)
    rep["heartCount"] = String(heartCount)
    rep["reportCount"] = String(heartCount)
    rep["authorID"] = authorID
    rep["members"] = members.joined(separator: "-")
    rep["isActive"] = String(isActive)
    rep["isLocked"] = String(isLocked)

    if let id = id {
      rep["id"] = id
    }
    
    return rep
  }
  
}

extension Post: Comparable {
  
  static func == (lhs: Post, rhs: Post) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Post, rhs: Post) -> Bool {
    return rhs.timestamp < lhs.timestamp
  }

}
