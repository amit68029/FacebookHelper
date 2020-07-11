//
//  FacebookLoginHelper.swift



import Foundation
import FacebookCore
import FacebookLogin
 
final class FacebookLoginHelper : NSObject {

    private let rootVC = UIApplication.shared.windows.first?.rootViewController
    static let shared = FacebookLoginHelper()
    typealias FaceBookCompletion = ((_ user: FacebookUser) -> Void)
    private var completion :FaceBookCompletion?
    
    private override init() {
    }
    
    public struct FacebookUser {
        var firstName : String?
        var lastName : String?
        var name : String?
        var profilePicUrl : String?
        var id : String
        
        init(with dict : [String:Any]) {
            func getString(with obj : Any?) -> String {
                guard let str = obj as? String  else {
                    guard  let str = obj as? NSNumber else {
                        guard let flag = obj as? Bool else {
                            return ""
                        }
                        return flag ? "1":"0"
                    }
                    return str.stringValue
                }
                return str
            }
            
            self.firstName = getString(with: dict["first_name"])
            self.lastName = getString(with: dict["last_name"])
            self.name = getString(with: dict["name"])
            self.id = getString(with: dict["id"])
            if let picture = dict["picture"] as? [String:Any] {
                if let data = picture["data"] as? [String:Any] {
                    self.profilePicUrl = getString(with: data["url"])
                }
            }
        }
    }
    
    func login(completion aCompletion: FaceBookCompletion?) {
        self.completion = aCompletion
        self.loginWithReadPermissions()
    }
    
}


extension FacebookLoginHelper {
    private func loginManagerDidComplete(_ result: LoginResult) {
        let alertController: UIAlertController
        switch result {
        case .cancelled:
            alertController = UIAlertController(
                title: "Login Cancelled",
                message: "User cancelled login.",
                preferredStyle: .alert
            )
            rootVC?.present(alertController, animated: true, completion: nil)
        case .failed(let error):
            alertController = UIAlertController(
                title: "Login Fail",
                message: "Login failed with error \(error)",
                preferredStyle: .alert
            )
            rootVC?.present(alertController, animated: true, completion: nil)

        case .success( _, _, _):
            self.createGraphRequest()
        }
    }
    
    private func loginWithReadPermissions() {
        if let _ = AccessToken.current {
            self.createGraphRequest()
        } else {
            let loginManager = LoginManager()
                    
            loginManager.logIn(
                permissions: [.publicProfile, .userFriends],
                viewController: rootVC ?? UIViewController()
            ) { result in
                self.loginManagerDidComplete(result)
            }
        }
        
    }
    
    
    private func createGraphRequest() {
        
        let connection = GraphRequestConnection()
        let myGraphRequest = GraphRequest(graphPath: "/me", parameters: ["fields": "id, name, first_name, last_name, email, birthday, age_range, picture.width(400), gender"], tokenString: AccessToken.current?.tokenString, version: Settings.defaultGraphAPIVersion, httpMethod: .get)
        
        connection.add(myGraphRequest) { (graphConnection, result, error) in
            if let err = error {
                print("FB Login Error:(\(err.localizedDescription))")
                return
            }
            if let dict = result as? [String:Any] {
                let obj = FacebookUser.init(with: dict)
                self.completion?(obj)
            }
        }

        connection.start()
    }
    
    private func logOut() {
        let loginManager = LoginManager()
        loginManager.logOut()
    }

}
