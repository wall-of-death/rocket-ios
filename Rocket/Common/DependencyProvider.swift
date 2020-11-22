//
//  DependencyProvider.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation
import AWSCognitoAuth
import AWSCore

struct DependencyProvider {
    var auth: AWSCognitoAuth
    var apiClient: APIClient
    var s3Bucket: String
}

extension DependencyProvider {

    #if DEBUG
    static func make() -> DependencyProvider {
        .make(config: DevelopmentConfig.self)
    }
    #endif
    static func make(config: Config.Type) -> DependencyProvider {
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .APNortheast1,
            identityPoolId: config.identityPoolId
        )
        
        let configuration = AWSServiceConfiguration(
            region: .APNortheast1,
            credentialsProvider: credentialProvider
        )
        
        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
        
        let cognitoConfiguration = AWSCognitoAuthConfiguration(
            appClientId: config.appClientId,
            appClientSecret: config.appClientSecret,
            scopes: config.scopes,
            signInRedirectUri: config.signInRedirectUri,
            signOutRedirectUri: config.signOutRedirectUri,
            webDomain: config.webDomain,
            identityProvider: nil,
            idpIdentifier: nil,
            userPoolIdForEnablingASF: config.userPoolIdForEnablingASF
        )
        
        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: "cognitoAuth")
        let auth = AWSCognitoAuth.init(forKey: "cognitoAuth")
        let idToken: String? = KeyChainClient().get(key: "ID_TOKEN")
        let apiClient = APIClient(baseUrl: URL(string: config.apiEndpoint)!, idToken: idToken)
        return DependencyProvider(auth: auth, apiClient: apiClient, s3Bucket: config.s3Bucket)
    }
}
