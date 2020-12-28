//
//  S3Client.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import AWSS3
import Foundation
import Photos
import AVFoundation
import AVKit

class S3Client {
    let s3Bucket: String
    let cognitoIdentityPoolCredentialProvider: AWSCognitoCredentialsProvider

    init(s3Bucket: String, cognitoIdentityPoolCredentialProvider: AWSCognitoCredentialsProvider) {
        self.s3Bucket = s3Bucket
        self.cognitoIdentityPoolCredentialProvider = cognitoIdentityPoolCredentialProvider
    }

    public func uploadImage(image: UIImage?, callback: @escaping ((Result<String, Error>) -> Void)) {
        let transferUtility = AWSS3TransferUtility.default()
        let key = "\(self.cognitoIdentityPoolCredentialProvider.identityId!)/\(UUID()).jpeg"
        print("======================\(key)=====================")
        let contentType = "application/jpeg"
        let im: UIImage = image ?? UIImage(named: "band")!
        guard let pngData = im.jpegData(compressionQuality: 0.25) else {
            callback(.failure(S3Error.invalidUrl("failed to convert image to data")))
            return
        }

        transferUtility.uploadData(
            pngData,
            bucket: s3Bucket,
            key: key,
            contentType: contentType,
            expression: AWSS3TransferUtilityUploadExpression(),
            completionHandler: {(task, error) -> Void in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error)
                        callback(.failure(error))
                    }
                    callback(.success("https://\(self.s3Bucket).s3-ap-northeast-1.amazonaws.com/\(key)"))
                }
            }
        ).continueWith { task in
            if let error = task.error {
                print(error)
                callback(.failure(error))
            }

            if let _ = task.result {
                DispatchQueue.main.async {
                    print("uploading...")
                }
            }

            return nil
        }
    }
    
    public func uploadMovie(url: URL, asset: PHAsset, callback: @escaping ((Result<String, Error>) -> Void)) {
        let transferUtility = AWSS3TransferUtility.default()
        let key = "\(UUID()).mp4"
        let contentType = "movie/mp4"
    
        PHImageManager().requestExportSession(forVideo: asset, options: nil, exportPreset: "AVAssetExportPresetLowQuality") { session, data in
            
            guard let session = session else {
                callback(.failure(S3Error.invalidUrl("session not found")))
                return
            }
            
            let filename = UUID().uuidString.appending(".mp4")
            let docurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let tempUrl = docurl.absoluteURL.appendingPathComponent(filename)
            
            session.outputURL = tempUrl
            session.outputFileType = .mp4
            session.exportAsynchronously() {
                let videoData = try! Data(contentsOf: tempUrl)
                print(videoData)
                let expression = AWSS3TransferUtilityUploadExpression()
                let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = {
                    (task, error) -> Void in
                    DispatchQueue.main.async {
                        if let error = error {
                            callback(.failure(error))
                        }
                        callback(.success("https://\(self.s3Bucket).s3-ap-northeast-1.amazonaws.com/\(key)"))
                    }
                }
                
                transferUtility.uploadData(
                    videoData,
                    bucket: self.s3Bucket,
                    key: key,
                    contentType: contentType,
                    expression: expression,
                    completionHandler: completionHandler
                ).continueWith { task in
                    if let error = task.error {
                        callback(.failure(error))
                    }

                    if let _ = task.result {
                        DispatchQueue.main.async {
                            print("uploading...")
                        }
                    }
                    return nil
                }
            }
        }
    }
}
