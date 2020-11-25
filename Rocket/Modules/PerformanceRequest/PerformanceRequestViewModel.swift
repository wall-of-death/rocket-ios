//
//  PerformanceRequestViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import UIKit
import Endpoint
import AWSCognitoAuth

class PerformanceRequestViewModel {
    enum Output {
        case getRequests([PerformanceRequest])
        case error(Error)
    }
    
    let apiClient: APIClient
    let s3Client: S3Client
    let user: User
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, s3Bucket: String, user: User, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.user = user
        self.outputHandler = outputHander
    }
    
    func getRequests() {
        var uri = GetPerformanceRequests.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        
        do {
            try apiClient.request(GetPerformanceRequests.self, request: req, uri: uri) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getRequests(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}
