//
//  CreateBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Endpoint
import Foundation
import UIKit

class CreateBandViewModel {
    enum Output {
        case create(Endpoint.Group)
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.outputHandler = outputHander
    }

    func create(
        name: String, englishName: String?, biography: String?,
        since: Date?, artwork: UIImage?, hometown: String?
    ) {
        self.s3Client.uploadImage(image: artwork) { [apiClient] (imageUrl, error) in
            if let error = error { self.outputHandler(.error(error as! Error)) }
            guard let imageUrl = imageUrl else { return }
            let req = CreateGroup.Request(
                name: name, englishName: englishName, biography: biography, since: since,
                artworkURL: URL(string: imageUrl), hometown: hometown)
            apiClient.request(CreateGroup.self, request: req) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.create(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }
}