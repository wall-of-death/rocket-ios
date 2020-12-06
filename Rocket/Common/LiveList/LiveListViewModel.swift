//
//  LiveListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class LiveListViewModel {
    enum Output {
        case getLives([Live])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let group: Group
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, group: Group, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.group = group
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getLives() {
        var uri = GetUpcomingLives.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        apiClient.request(GetUpcomingLives.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getLives(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

