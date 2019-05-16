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
import FirebaseDatabase
import FirebaseFirestore

final class AppController {
  
  static let shared = AppController()
  let presenceManager = OnlineOfflineManager()
    
  init() {  
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userStateDidChange),
      name: Notification.Name.AuthStateDidChange,
      object: nil
    )
  }
    
  static public var user: User?
    

  private var window: UIWindow!
  private var rootViewController: UIViewController? {
    didSet {
      if let vc = rootViewController {
        window.rootViewController = vc
      }
    }
  }
  
  // MARK: - Helpers
  
  func show(in window: UIWindow?) {
    guard let window = window else {
      fatalError("Cannot layout app with a nil window.")
    }
    
    //FirebaseApp.configure()
    
    // TODO: remove this once logout is handled
//    do {
//        try Auth.auth().signOut()
//    } catch {
//        print("Error signing out: \(error.localizedDescription)")
//    }
//    
//    // TODO: remove when done testing
//    let domain = Bundle.main.bundleIdentifier!
//    UserDefaults.standard.removePersistentDomain(forName: domain)
//    UserDefaults.standard.synchronize()
    
    self.window = window
    window.tintColor = .primary
    window.backgroundColor = .white
    
    handleAppState()
    
    window.makeKeyAndVisible()
  }
    
    func signIn(link: String) {
        if let email = UserDefaults.standard.string(forKey: "Email") {
            if Auth.auth().isSignIn(withEmailLink: link) {
                Auth.auth().signIn(withEmail: email, link: link) { (user, error) in
                    if (error != nil) {
                        print(error!)
                    }
                    if let userQuery = user {
                        Analytics.logEvent("user_completed_onboarding", parameters: [
                            "email": userQuery.user.uid as! NSObject
                            ])
                    }


//                    let newStudent = Student(uid: user!.uid, username: name, bio: "", createdDate: Date())
//                        studentsReference.document(newStudent.uid).setData(newStudent.representation) { error in
//                            if error != nil {
//                                ProgressHUD.showError(error!.localizedDescription)
//                                return
//                            }
//                            ProgressHUD.showSuccess("Success")
                    //        /*
                    //        studentsReference.addDocument(data: newStudent.representation) { error in
                    //            if error != nil {
                    //                ProgressHUD.showError(error!.localizedDescription)
                    //                return
                    //            }
                    //            ProgressHUD.showSuccess("Success")
                    //        }
                    //        */
                    //
                    //    }
                }
            }
        }
    }
  
  private func handleAppState() {
    if let user = Auth.auth().currentUser {
        AppController.user = user
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if AppSettings.displayName != nil {
            presenceManager.markUserOnline()

            PushNotificationManager.shared.userID = user.uid
            PushNotificationManager.shared.updateFirestorePushTokenIfNeeded()
            
            let tabContoller = storyboard.instantiateViewController(withIdentifier: "TabBarController")
            rootViewController = tabContoller
        } else {
            let handleContoller = storyboard.instantiateViewController(withIdentifier: "HandleSelectionViewController")
            rootViewController = handleContoller
        }
        
    } else {
       let storyboard = UIStoryboard(name: "Main", bundle: nil)
       let infoContoller = storyboard.instantiateViewController(withIdentifier: "InfoViewController")
       rootViewController = infoContoller
    }
  }
  
  // MARK: - Notifications
  
  @objc internal func userStateDidChange() {
    DispatchQueue.main.async {
      self.handleAppState()
    }
  }
  
}
