//
//  BandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class BandViewModel {
    enum Output {
        case getContents([GroupFeed])
        case getLives([LiveFeed])
        case getCharts([ChannelDetail.ChannelItem])
        case getBands([Group])
        case reserveTicket(Ticket)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let youTubeDataApiClient: YouTubeDataAPIClient
    let outputHandler: (Output) -> Void
    
    var bandPagenation: Pagenation = Pagenation<GetAllGroups>(requestUri: GetAllGroups.URI(), event: .isInitial)

    init(apiClient: APIClient, youTubeDataApiClient: YouTubeDataAPIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.youTubeDataApiClient = youTubeDataApiClient
        self.auth = auth
        self.outputHandler = outputHander
    }

    func getContents() {
        var uri = GetFollowingGroupFeeds.URI()
        uri.page = 1
        uri.per = 100
        apiClient.request(GetFollowingGroupFeeds.self, request: Empty(), uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getContents(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
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

    func getGroups(isNext: Bool = true) {
        if !isNext && bandPagenation.event != .isLoading { bandPagenation.event = .isInitial }
        
        print(bandPagenation.event)
        
        switch bandPagenation.event {
        case .isInitial:
            bandPagenation.requestUri.page = 1
            bandPagenation.requestUri.per = per
            bandPagenation.event = .isLoading
            
            apiClient.request(GetAllGroups.self, request: Empty(), uri: bandPagenation.requestUri) { result in
                switch result {
                case .success(let res):
                    self.bandPagenation.event = .isFinished
                    self.outputHandler(.getBands(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        case .isFinished:
            bandPagenation.requestUri.per += 1
            bandPagenation.event = .isLoading
            
            apiClient.request(GetAllGroups.self, request: Empty(), uri: bandPagenation.requestUri) { result in
                switch result {
                case .success(let res):
                    self.bandPagenation.event = .isFinished
                    self.outputHandler(.getBands(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        default:
            break
        }
    }

    func getCharts() {
//        let request = Empty()
//        var uri = ListChannel.URI()
//        uri.key = youTubeDataApiClient.getApiKey()
//        uri.channelId = "UCxjXU89x6owat9dA8Z-bzdw"
//        uri.part = "snippet"
//        youTubeDataApiClient.request(ListChannel.self, request: request, uri: uri) { result in
//            switch result {
//            case .success(let res):
//                self.outputHandler(.getCharts(res.items))
//            case .failure(let error):
//                self.outputHandler(.error(error))
//            }
//        }
    }

    func reserveTicket(liveId: Live.ID) {
        let request = ReserveTicket.Request(liveId: liveId)
        apiClient.request(ReserveTicket.self, request: request) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.reserveTicket(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}
