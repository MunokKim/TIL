//
//  LoginViewController.swift
//  HowlTalk
//
//  Created by 김문옥 on 2018. 4. 5..
//  Copyright © 2018년 김문옥. All rights reserved.
//

import UIKit
import Firebase
import TextFieldEffects
import MaterialComponents
import GoogleSignIn
import FBSDKLoginKit


class LoginViewController: UIViewController, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {

    @IBOutlet weak var emailTextField: YokoTextField!
    @IBOutlet weak var passwordTextField: YokoTextField!
    @IBOutlet weak var loginButton: MDCRaisedButton!
    @IBOutlet weak var signupButton: MDCFlatButton!
    @IBOutlet weak var facebookLoginButton: FBSDKLoginButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let remoteconfig = RemoteConfig.remoteConfig()
    var color: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicatorView.stopAnimating()

        GIDSignIn.sharedInstance().uiDelegate = self
        facebookLoginButton.delegate = self
        facebookLoginButton.readPermissions = ["email"]

        // 상태바 그리기
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            
            // iPhone X 판별
            if UIScreen.main.nativeBounds.height == 2436 {
                
                m.height.equalTo(40)
            } else {
                
                m.height.equalTo(20)
            }
            
            
        }
        color = remoteconfig["splash_background"].stringValue
        
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
//        signinButton.backgroundColor = UIColor(hex: color)
        signupButton.customTitleColor = UIColor(hex: color)

//
//        signinButton.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)
        
        
        // Create a Raised Button
        // See https://material.io/guidelines/what-is-material/elevation-shadows.html
        
        loginButton.setElevation(ShadowElevation(rawValue: 4), for: .normal)
//        loginButton.setTitle("Tap Me Too", for: .normal)
        loginButton.sizeToFit()
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        self.view.addSubview(loginButton)
        
        // Create a Flat Button
        
//        signinButton.setTitle("Tap me", for: .normal)
        signupButton.sizeToFit()
        signupButton.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)
        self.view.addSubview(signupButton)
        
        // 로그아웃
        try! Auth.auth().signOut()
        
        // 로그인 상태가 되기를 지켜보다가 메인뷰로 화면을 넘긴다
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                
                self.moveToMainViewTabBarController()
            }
        }
    }
    
    @IBAction func pressReturnInEmail(_ sender: Any) {
        
        self.passwordTextField.becomeFirstResponder() // 텍스트필드에 포커스
    }
    @IBAction func pressReturnInpassword(_ sender: Any) {
        
        self.view.endEditing(true)
        loginEvent()
    }
    
    @IBAction func googleLogin(_ sender: Any) {
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    @objc func loginEvent() {
        
        self.activityIndicatorView.startAnimating()
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, err) in
            
            guard err == nil else {
                print(err.debugDescription)
                
                var errMessage = err.debugDescription
                let strArray = err.debugDescription.components(separatedBy: "\"")
                
                // "aaaaaa\"aaaaaaa\"aaaaaaa"
                if strArray.count == 3 {
                    errMessage = strArray[1]
                }
                
                let alert = UIAlertController(title: "로그인 에러", message: errMessage, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { (action) in
                    self.emailTextField.text! = ""
                    self.passwordTextField.text! = ""
                    self.emailTextField.becomeFirstResponder() // 텍스트필드에 포커스
                }))
                
                self.present(alert, animated: true, completion: nil)

                self.activityIndicatorView.stopAnimating()
                
                return
            }
            
            self.activityIndicatorView.stopAnimating()
            
            self.moveToMainViewTabBarController()
        }
    }
    
    func moveToMainViewTabBarController() {
        
        if let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as? UITabBarController {
            
            self.present(view, animated: true, completion: nil)
        }
        
        // 토큰 생성
        let uid = Auth.auth().currentUser?.uid
        
        if let token = InstanceID.instanceID().token() {
            
            Database.database().reference().child("users").child(uid!).updateChildValues(["pushToken" : token])
        }
    }
    
    @objc func presentSignup() {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignUpViewController
        self.present(view, animated: true, completion: nil)
    }
    
    // 빈곳을 터치하면 키보드나 데이트피커 등을 숨긴다
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult?, error: Error!) {
        if(result?.token == nil){
            return
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            // ...
            if let error = error {
                return
            }
            
            // User is signed in
            // ...
            
            // 유저명을 FCM 서버로 전달
            //            user?.createProfileChangeRequest().displayName = self.nameTextField.text!
            //            user?.createProfileChangeRequest().commitChanges(completion: nil)
            
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = (user?.providerData[0].displayName)!
            changeRequest?.commitChanges(completion: nil)
            
            let photoUrl = (user?.providerData[0].photoURL)!.absoluteString
            
            let values = [
                "profileImageUrl" : photoUrl,
                "email" : (user?.providerData[0].email)!,
                "username" : (user?.providerData[0].displayName)!,
                "uid" : Auth.auth().currentUser?.uid
                ] as [String : Any]
            
            // 구글계정 이메일이 DB에 등록이 안되어 있는 경우 등록
            Database.database().reference().child("users").child((user?.uid)!).setValue(values, withCompletionBlock: { (err, ref) in
                if err != nil {
                    
                    print("err.debugDescription : \(err.debugDescription)")
                    return
                }
                
                // 토큰 생성
                let uid = Auth.auth().currentUser?.uid
                
                if let token = InstanceID.instanceID().token() {
                    
                    Database.database().reference().child("users").child(uid!).updateChildValues(["pushToken" : token])
                }
                
                // image url을 data로 바꾼다
                guard let image = try? Data(contentsOf: (user?.providerData[0].photoURL)!) else {
                    print("image url to data fail")
                    return
                }
                
                Storage.storage().reference().child("userImages").child((user?.uid)!).putData(image, metadata: nil, completion: { (data, error) in
                    
                    if error != nil {
                        print("error.debugDescription\(error.debugDescription)")
                        return
                    }
                    
                })
                
            })

        }
        FBSDKLoginManager().logOut()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
        FBSDKLoginManager().logOut();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
