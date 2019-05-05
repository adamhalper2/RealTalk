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
import FirebaseAuth
import FirebaseFirestore
import ProgressHUD

class HandleSelectionViewController: UIViewController {
  
  @IBOutlet var actionButton: UIButton!
  @IBOutlet var displayNameField: UITextField!

  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
    
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    displayNameField.tintColor = .primary
    displayNameField.addTarget(
      self,
      action: #selector(textFieldDidReturn),
      for: .primaryActionTriggered
    )
    
    registerForKeyboardNotifications()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    displayNameField.becomeFirstResponder()
  }
  
  // MARK: - Actions
  
  @IBAction func actionButtonPressed() {
    signIn()
  }
  
  @objc private func textFieldDidReturn() {
    signIn()
  }
  
  // MARK: - Helpers
  
  private func registerForKeyboardNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }
  
  private func signIn() {
    guard let name = displayNameField.text, !name.isEmpty else {
      showMissingNameAlert()
      return
    }
    
    displayNameField.resignFirstResponder()
    
    AppSettings.displayName = name

    let db = Firestore.firestore()
    let  studentsReference =  db.collection("students")
    if let user = AppController.user {
        let uid = user.uid
        let newStudent = Student(uid: uid, username: name, bio: "", createdDate: Date())
        studentsReference.document(newStudent.uid).setData(newStudent.representation) { error in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            ProgressHUD.showSuccess("Success")
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
            
            AppController.shared.userStateDidChange()
        }
        
    }
    
  }
    

  private func showMissingNameAlert() {
    let ac = UIAlertController(title: "Display Name Required", message: "Please enter a display name.", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
      DispatchQueue.main.async {
        self.displayNameField.becomeFirstResponder()
      }
    }))
    present(ac, animated: true, completion: nil)
  }
    
  private func invalidEmailAlert() {
    let ac = UIAlertController(title: "Invalid Email", message: "Please enter a valid university (.edu) email.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.displayNameField.becomeFirstResponder()
            }
        }))
        present(ac, animated: true, completion: nil)
  }
    
  private func emailSentAlert() {
    let ac = UIAlertController(title: "Log in Link Sent", message: "Please check your email for a log in link.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.displayNameField.becomeFirstResponder()
            }
        }))
    present(ac, animated: true, completion: nil)
  }
  
  // MARK: - Notifications
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let userInfo = notification.userInfo else {
      return
    }
    guard let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
      return
    }
    guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
      return
    }
    guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
      return
    }
    
    let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve << 16)
    
    UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let userInfo = notification.userInfo else {
      return
    }
    guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
      return
    }
    guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
      return
    }
    
    let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve << 16)
    
    UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
}
