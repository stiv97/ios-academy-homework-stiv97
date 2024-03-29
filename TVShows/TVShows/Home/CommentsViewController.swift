//
//  CommentsViewController.swift
//  TVShows
//
//  Created by Sandro Domitran on 02/08/2019.
//  Copyright © 2019 Sandro Domitran. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import CodableAlamofire

class CommentsViewController: UIViewController {
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    
    var loginUser: LoginUser?
    var episodeId: String?
    private var comments: [Comment]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentsTableView.dataSource = self

        SVProgressHUD.show()
        loadComments()
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func postButtonPressed(_ sender: Any) {
        postComment()
    }
    
    private func loadComments() {
        guard let token = loginUser?.token
            else {
                print("Invalid user")
                return
        }
        guard let episodeId = episodeId
            else {
                print("Invalid episode")
                return
        }
        
        let headers = ["Authorization" : token]
        Alamofire
            .request("https://api.infinum.academy/api/episodes/" + episodeId + "/comments",
                     method: .get,
                     encoding: JSONEncoding.default,
                     headers: headers
            )
            .validate()
            .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {
                [weak self] (response: DataResponse<[Comment]>) in
                
                guard let self = self else { return }
                SVProgressHUD.dismiss()
                switch response.result {
                case .success(let comments):
                    self.comments = comments
                    self.commentsTableView.reloadData()
                case .failure(let error):
                    print("API failure: \(error)")
                }
        }
    }
    private func postComment(){
        guard let token = loginUser?.token
            else {
                print("Invalid user")
                return
        }
        let headers = ["Authorization" : token]
        let parameters: [String:String] = [
            "text": commentTextField.text ?? "",
            "episodeId": episodeId ?? "",
            
        ]
        
        Alamofire
            .request("https://api.infinum.academy/api/comments",
                     method: .post,
                     parameters: parameters,
                     encoding: JSONEncoding.default,
                     headers: headers
            )
            .validate()
            .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) { (response: DataResponse<Comment>) in
                SVProgressHUD.dismiss()
                switch response.result {
                case .success:
                    print("Success")
                    self.loadComments()
                case .failure(let error):
                    self.alertMessage(title: "Failed", message: "API failure")
                    print(error)
                }
        }
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let comments = self.comments else { return 0 }
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentsTableView.dequeueReusableCell(withIdentifier: "CommentsCell") as! CommentsCell
        if let comment = comments?[indexPath.row] {
            cell.setUsernameLabel(username: comment.userEmail)
            cell.setCommentLabel(comment: comment.text)
        }
        return cell
    }
}
