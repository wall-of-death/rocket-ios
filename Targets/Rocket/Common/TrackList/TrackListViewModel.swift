//
//  TrackListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import UIKit
import Endpoint
import Combine
import InternalDomain

class TrackListViewModel {
    typealias Input = DataSource
    
    enum DataSource {
        case searchYouTubeResults(String)
        case searchAppleMusicResults(String)
        case none
    }
    
    enum DataSourceStorage {
        case searchYouTubeResults(YouTubePaginationRequest<ListChannel>)
        case searchAppleMusicResults(AppleMusicPaginationRequest<SearchSongs>)
        case none
        
        init(dataSource: DataSource, dependencyProvider: LoggedInDependencyProvider) {
            switch dataSource {
            case .searchYouTubeResults(let query):
                var uri = ListChannel.URI()
                uri.q = query
                uri.part = "snippet"
                uri.order = "viewCount"
                let request = YouTubePaginationRequest<ListChannel>(apiClient: dependencyProvider.youTubeDataApiClient, uri: uri)
                self = .searchYouTubeResults(request)
            case .searchAppleMusicResults(let query):
                var uri = SearchSongs.URI()
                uri.term = query
                uri.types = "songs"
                let request = AppleMusicPaginationRequest<SearchSongs>(apiClient: dependencyProvider.appleMusicApiClient, uri: uri)
                self = .searchAppleMusicResults(request)
            case .none:
                self = .none
            }
        }
        
    }
    
    struct State {
        var isToSelect: Bool = false
        var tracks: [InternalDomain.Track] = []
    }
    
    enum TrackType {
        case youtube
        case appleMusic
    }
    
    enum Output {
        case reloadTableView
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    
    var storage: DataSourceStorage
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, dependencyProvider: dependencyProvider)
                
        subscribe(storage: storage)
    }
    
    func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .searchYouTubeResults(pagination):
            pagination.subscribe { [weak self] result in
                switch result {
                case .initial(let res):
                    self?.state.tracks = res.items.map {
                        Track(
                            name: $0.snippet?.title ?? "no title",
                            artistName: $0.snippet?.channelTitle ?? "no artist",
                            artwork: $0.snippet?.thumbnails?.high?.url ?? "",
                            trackType: .youtube($0.id.videoId ?? "")
                        )
                    }
                    self?.outputSubject.send(.reloadTableView)
                case .next(let res):
                    self?.state.tracks += res.items.map {
                        Track(
                            name: $0.snippet?.title ?? "no title",
                            artistName: $0.snippet?.channelTitle ?? "no artist",
                            artwork: $0.snippet?.thumbnails?.high?.url ?? "",
                            trackType: .youtube($0.id.videoId ?? "")
                        )
                    }
                    self?.outputSubject.send(.reloadTableView)
                case .error(let err):
                    self?.outputSubject.send(.error(err))
                }
            }
        case .searchAppleMusicResults(let pagination):
            pagination.subscribe { [weak self] result in
                switch result {
                case .initial(let res):
                    self?.state.tracks = res.results.songs.data.map {
                        Track(
                            name: $0.attributes.name,
                            artistName: $0.attributes.artistName,
                            artwork: $0.attributes.artwork.url?.replacingOccurrences(of: "{w}", with: String($0.attributes.artwork.width)).replacingOccurrences(of: "{h}", with: String($0.attributes.artwork.height)) ?? "",
                            trackType: .appleMusic($0.id)
                        )
                    }
                    self?.outputSubject.send(.reloadTableView)
                case .next(let res):
                    self?.state.tracks += res.results.songs.data.map {
                        Track(
                            name: $0.attributes.name,
                            artistName: $0.attributes.artistName,
                            artwork: $0.attributes.artwork.url?.replacingOccurrences(of: "{w}", with: String($0.attributes.artwork.width)).replacingOccurrences(of: "{h}", with: String($0.attributes.artwork.height)) ?? "",
                            trackType: .appleMusic($0.id)
                        )
                    }
                    self?.outputSubject.send(.reloadTableView)
                case .error(let err):
                    self?.outputSubject.send(.error(err))
                }
            }
        case .none: break
        }
    }
    
    func inject(_ input: Input, isToSelect: Bool = false) {
        self.storage = DataSourceStorage(dataSource: input, dependencyProvider: dependencyProvider)
        self.state.isToSelect = isToSelect
        subscribe(storage: storage)
        refresh()
    }
    
    func refresh() {
        switch storage {
        case let .searchYouTubeResults(pagination):
            pagination.refresh()
        case let .searchAppleMusicResults(pagination):
            pagination.refresh()
        case .none: break
        }
    }
     
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.tracks.count else { return }
        switch storage {
        case let .searchYouTubeResults(pagination):
            pagination.next()
        case let .searchAppleMusicResults(pagination):
            pagination.next()
        case .none: break
        }
    }
}