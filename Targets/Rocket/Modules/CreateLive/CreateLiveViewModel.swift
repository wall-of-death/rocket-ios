//
//  CreateLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/01/08.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class CreateLiveViewModel {
    struct State {
        var title: String?
        var performers: [Group] = []
        var livehouse: String?
        var date: String?
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didCreateLive(Live)
        case updateSubmittableState(PageState)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createLiveAction = Action(CreateLive.self, httpClient: apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        let errors = Publishers.MergeMany(
            createLiveAction.errors
        )
        
        Publishers.MergeMany(
            createLiveAction.elements.map { _ in .updateSubmittableState(.editting(true)) }.eraseToAnyPublisher(),
            createLiveAction.elements.map(Output.didCreateLive).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func didUpdateInputItems(
        title: String?, livehouse: String?, date: String?
    ) {
        state.title = title
        state.livehouse = livehouse
        state.date = date
        submittable()
    }
    
    func addGroup(_ group: Group) {
        state.performers.append(group)
        submittable()
    }
    
    func removeGroup(_ groupName: String) {
        state.performers = state.performers.filter { $0.name != groupName.prefix(groupName.count - 2) }
        submittable()
    }
    
    func submittable() {
        let isSubmittable: Bool = (
            state.title != nil &&
            state.livehouse != nil &&
            state.date != nil &&
            !state.performers.isEmpty
        )
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }

    func didRegisterButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        createLive()
    }
    
    private func createLive() {
        guard let title = state.title else { return }
        guard let livehouse = state.livehouse else { return }
        guard let date = state.date else { return }
        guard let performer = state.performers.first else { return }
        var type: LiveStyleInput
        switch state.performers.count {
        case 1: type = .oneman(performer: performer.id)
        case 2, 3, 4: type = .battle(performers: state.performers.map { $0.id })
        default: type = .festival(performers: state.performers.map { $0.id })
        }
        let req = CreateLive.Request(
            title: title,
            style: type,
            price: 5000,
            artworkURL: performer.artworkURL,
            hostGroupId: performer.id,
            liveHouse: livehouse,
            date: date,
            endDate: nil,
            openAt: "17:00",
            startAt: "18:00",
            piaEventCode: nil,
            piaReleaseUrl: nil,
            piaEventUrl: nil
        )
        createLiveAction.input((request: req, uri: CreateLive.URI()))
    }
}

