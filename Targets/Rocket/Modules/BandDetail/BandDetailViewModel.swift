//
//  BandDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import Endpoint
import Foundation
import Combine
import InternalDomain

class BandDetailViewModel {
    enum DisplayType {
        case fan
        case group
        case member
    }
    enum Section {
        case live(rows: [Live])
        case feed(rows: [ArtistFeedSummary])
    }
    struct State {
        var group: Group
        var lives: [Live] = []
        var feeds: [ArtistFeedSummary] = []
        var groupItem: ChannelDetail.ChannelItem? = nil
        var groupDetail: GetGroup.Response?
        let role: RoleProperties

        var sections: [Section] {
            [.live(rows: lives), .feed(rows: feeds)]
        }
    }

    enum Output {
        case didGetGroupDetail(GetGroup.Response, displayType: DisplayType)
        case didGetGroupLives
        case didGetGroupFeeds
        case didGetChart(Group, ChannelDetail.ChannelItem?)
        case didCreatedInvitation(InviteGroup.Invitation)

        case pushToLiveDetail(Live)
        case openURLInBrowser(URL)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    

    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider, group: Group
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(group: group, role: dependencyProvider.user.role)
    }

    func numberOfSections() -> Int { state.sections.count }
    func numberOfRows(in section: Int) -> Int {
        switch state.sections[section] {
        case let .feed(rows): return rows.count
        case let .live(rows): return rows.count
        }
    }
    func didSelectRow(at indexPath: IndexPath) {
        switch state.sections[indexPath.row] {
        case let .live(rows):
            let live = rows[indexPath.row]
            outputSubject.send(.pushToLiveDetail(live))
        case let .feed(rows):
            let feed = rows[indexPath.row]
            switch feed.feedType {
            case .youtube(let url):
                outputSubject.send(.openURLInBrowser(url))
            }
        }
    }

    // MARK: - Inputs
    func viewDidLoad() {
        refresh()
    }

    func refresh() {
        getGroupDetail()
        getChartSummary()
        getGroupLiveSummary()
        getGroupFeedSummary()
    }

    func inviteGroup(groupId: Group.ID) {
        let request = InviteGroup.Request(groupId: groupId)
        apiClient.request(InviteGroup.self, request: request) { [outputSubject] result in
            switch result {
            case .success(let invitation):
                outputSubject.send(.didCreatedInvitation(invitation))
            case .failure(let error):
                outputSubject.send(.reportError(error))
            }
        }
    }

    private func getGroupDetail() {
        var uri = GetGroup.URI()
        uri.groupId = state.group.id
        apiClient.request(GetGroup.self, request: Empty(), uri: uri) { [unowned self] result in
            switch result {
            case .success(let response):
                state.group = response.group
                state.groupDetail = response
                let displayType: DisplayType = {
                    switch state.role {
                    case .fan: return .fan
                    case .artist:
                        return response.isMember ? .group : .member
                    }
                }()
                outputSubject.send(.didGetGroupDetail(response, displayType: displayType))
            case .failure(let error):
                self.outputSubject.send(.reportError(error))
            }
        }
    }

    private func getGroupLiveSummary() {
        let request = Empty()
        var uri = Endpoint.GetGroupLives.URI()
        uri.page = 1
        uri.per = 1
        uri.groupId = state.group.id
        apiClient.request(GetGroupLives.self, request: request, uri: uri) { [unowned self] result in
            switch result {
            case .success(let lives):
                self.state.lives = lives.items
                self.outputSubject.send(.didGetGroupLives)
            case .failure(let error):
                self.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func getGroupFeedSummary() {
        var uri = GetGroupFeed.URI()
        uri.groupId = state.group.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        apiClient.request(GetGroupFeed.self, request: request, uri: uri) { [unowned self] result in
            switch result {
            case .success(let res):
                self.state.feeds = res.items
                self.outputSubject.send(.didGetGroupFeeds)
            case .failure(let error):
                self.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func getChartSummary() {
        guard let youtubeChannelId = state.group.youtubeChannelId else { return }
        let request = Empty()
        var uri = ListChannel.URI()
        uri.key = dependencyProvider.youTubeDataApiClient.getApiKey()
        uri.channelId = youtubeChannelId
        uri.part = "snippet"
        uri.maxResults = 1
        uri.order = "viewCount"
        dependencyProvider.youTubeDataApiClient
            .request(ListChannel.self, request: request, uri: uri) { [unowned self] result in
                switch result {
                case .success(let res):
                    self.outputSubject.send(.didGetChart(self.state.group, res.items.first))
                case .failure(let error):
                    self.outputSubject.send(.reportError(error))
                }
            }
    }
}