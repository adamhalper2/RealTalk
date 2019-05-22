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
  let updateTimestamp: NSDate
  var commentCount: Int
  var heartCount: Int
  var reportCount: Int
  var members: [String]
  var isActive: Bool
  var isLocked: Bool
  var bannedList: [String]
  var lastMessage: String
  var pollID: String
  
  
    init(content: String, author: String, timestamp: NSDate, authorID: String) {
        self.id = nil
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
        self.bannedList = []
        self.lastMessage = ""
        self.updateTimestamp = timestamp
        self.pollID = ""
    }

    init(content: String, author: String, timestamp: NSDate, authorID: String, pollID: String) {
        self.id = nil
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
        self.bannedList = []
        self.lastMessage = ""
        self.updateTimestamp = timestamp
        self.pollID = pollID
    }
    
    init?(data: [String: Any], docId: String) {
    
        guard let content = data["content"] as? String else {
            return nil
        }
        
        guard let author = data["author"] as? String else {
            return nil
        }
        
        guard let timestamp = data["timestamp"] as? String else {
            return nil
        }
        
        guard let updateTimestamp = data["updateTimestamp"] as? String else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy hh:mm:ss a ZZ"
        
        var date = NSDate()
        if let realDate = dateFormatter.date(from: timestamp) as? NSDate {
            date = realDate
        }
        
        var updateDate = NSDate()
        if let realUpdateDate = dateFormatter.date(from: updateTimestamp) as? NSDate {
            updateDate = realUpdateDate
        }
        
        guard let authorID = data["authorID"] as? String else {
            return nil
        }

        guard let pollID = data["pollID"] as? String else {
            return nil
        }

        guard let lastMessage = data["lastMessage"] as? String else {
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
        
        guard let bannedListStr = data["bannedList"] as? String else {
            return nil
        }


        let bannedList = bannedListStr.components(separatedBy: "-")
        
        self.id = docId
        
        self.content = content
        self.author = author
        self.commentCount = commentCountInt
        self.heartCount = heartCountInt
        self.reportCount = reportCountInt
        self.timestamp = date
        self.members = members
        self.authorID = authorID
        self.pollID = pollID
        self.isActive = isActiveBool
        self.isLocked = isLockedBool
        self.bannedList = bannedList
        self.updateTimestamp = updateDate
        self.lastMessage = lastMessage
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
    
    guard let updateTimestamp = data["updateTimestamp"] as? String else {
        return nil
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yy hh:mm:ss a ZZ"
    
    var date = NSDate()
    if let actualDate = dateFormatter.date(from: timestamp) as? NSDate {
        date = actualDate
    }
    
    var updateDate = NSDate()
    if let realUpdateDate = dateFormatter.date(from: updateTimestamp) as? NSDate {
        updateDate = realUpdateDate
    }

    guard let authorID = data["authorID"] as? String else {
        return nil
    }

    guard let pollID = data["pollID"] as? String else {
        return nil
    }
    
    guard let lastMessage = data["lastMessage"] as? String else {
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
    
    guard let bannedListStr = data["bannedList"] as? String else {
        return nil
    }
    let bannedList = bannedListStr.components(separatedBy: "-")
    
    id = document.documentID
    
    self.content = content
    self.author = author
    self.commentCount = commentCountInt
    self.heartCount = heartCountInt
    self.reportCount = reportCountInt
    self.timestamp = date
    self.members = members
    self.authorID = authorID
    self.pollID = pollID
    self.isActive = isActiveBool
    self.isLocked = isLockedBool
    self.bannedList = bannedList
    self.updateTimestamp = updateDate
    self.lastMessage = lastMessage
  }
}

extension Post : DatabaseRepresentation {

  
  var representation: [String : Any] {
    var rep = ["content": content]
    rep["author"] = author
    rep["timestamp"] = timestamp.toString(dateFormat: "MM/dd/yy hh:mm:ss a ZZ")
    rep["updateTimestamp"] = updateTimestamp.toString(dateFormat: "MM/dd/yy hh:mm:ss a ZZ")
    rep["commentCount"] = String(commentCount)
    rep["heartCount"] = String(heartCount)
    rep["reportCount"] = String(heartCount)
    rep["authorID"] = authorID
    rep["pollID"] = pollID
    rep["members"] = members.joined(separator: "-")
    rep["isActive"] = String(isActive)
    rep["isLocked"] = String(isLocked)
    rep["bannedList"] = bannedList.joined(separator: "-")
    rep["lastMessage"] = lastMessage

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
    return lhs.updateTimestamp < rhs.updateTimestamp
  }

}

