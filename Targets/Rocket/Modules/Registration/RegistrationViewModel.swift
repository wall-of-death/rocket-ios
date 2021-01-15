//
//  RegistrationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import AWSCognitoAuth
import Endpoint
import Foundation
import Combine

class RegistrationViewModel {
    enum Output {
        case signupStatus(Bool)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var signupStatus = Action(SignupStatus.self, httpClient: self.apiClient)
    
    init(auth: AWSCognitoAuth, apiClient: APIClient) {
        self.auth = auth
        self.apiClient = apiClient
        
        Publishers.MergeMany(
            signupStatus.elements.map {
                .signupStatus($0.isSignedup)
            }.eraseToAnyPublisher(),
            signupStatus.errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }

    func getSignupStatus() {
        signupStatus.input((request: Empty(), uri: SignupStatus.URI()))
    }
}
