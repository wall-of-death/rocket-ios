//
//  EditLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIKit

class EditLiveViewModel {
    struct State {
        var title: String?
        var date: String?
        var livehouse: String?
        var performers: [Group]
        let live: Live
    }
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter
    }()
    
    let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum DatePickerType {
        case openAt(Date)
        case startAt(Date)
    }
    
    enum Output {
        case didEditLive(Live)
        case didInject
        case updateSubmittableState(PageState)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var editLiveAction = Action(EditLive.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(
            title: live.title,
            date: live.date,
            livehouse: live.liveHouse,
            performers: live.performers,
            live: live
        )
        
        editLiveAction.elements
            .map(Output.didEditLive).eraseToAnyPublisher()
            .merge(with: editLiveAction.errors.map(Output.reportError).eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        editLiveAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        inject()
    }
    
    func inject() {
        outputSubject.send(.didInject)
    }
    
    func didUpdateInputItems(
        title: String?, livehouse: String?, date: String?
    ) {
        state.title = title
        state.livehouse = livehouse
        state.date = date
        
        let isSubmittable: Bool = (title != nil && livehouse != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
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

    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        let artworkUrl = state.performers.first?.artworkURL
        editLive(imageUrl: artworkUrl)
    }
    
    private func editLive(imageUrl: URL?) {
        var uri = EditLive.URI()
        uri.id = state.live.id
        guard let performer = state.performers.first else { return }
        var style: LiveStyleInput
        switch state.performers.count {
        case 1:
            style = .oneman(performer: performer.id)
        case 2, 3, 4:
            style = .battle(performers: state.performers.map { $0.id })
        default:
            style = .festival(performers: state.performers.map { $0.id })
        }
        
        let req = EditLive.Request(
            title: state.title ?? state.live.title,
            style: style,
            price: 5000,
            artworkURL: imageUrl,
            hostGroupId: performer.id,
            liveHouse: state.livehouse ?? state.live.liveHouse,
            date: state.date,
            endDate: nil,
            openAt: "17:00",
            startAt: "18:00",
            piaEventCode: nil,
            piaReleaseUrl: nil,
            piaEventUrl: nil
        )
        editLiveAction.input((request: req, uri: uri))
    }
}
