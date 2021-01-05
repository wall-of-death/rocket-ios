//
//  Pagenation.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/12.
//

import Endpoint

enum PaginationEvent<Response> {
    case initial(Response)
    case next(Response)
    case error(Error)
}

protocol PageResponse {
    associatedtype Item
    var items: [Item] { get }
    var metadata: PageMetadata { get }
}

extension Page: PageResponse {}

class PaginationRequest<E: EndpointProtocol> where E.URI: PaginationQuery, E.Request == Endpoint.Empty,
                                                   E.Response: PageResponse {
    private var uri: E.URI
    private var apiClient: APIClient
    private var subscribers: [(Event) -> Void] = []
    
    fileprivate struct State {
        var isInitial = true
        var isLoading = false
        var isFinished = false
    }

    fileprivate let state = CurrentValueSubject<State, Never>(State())

    typealias Event = PaginationEvent<E.Response>
    
    init(apiClient: APIClient, uri: E.URI = E.URI()) {
        self.apiClient = apiClient
        self.uri = uri
        
        self.initialize()
    }
    
    func subscribe(_ subscriber: @escaping (Event) -> Void) {
        subscribers.append(subscriber)
    }
    
    private func notify(_ response: Event) {
        subscribers.forEach { $0(response) }
    }
    
    private func initialize() {
        
        self.uri.page = 1
        self.uri.per = per
    }

    func refresh() {
        self.initialize()
        state.value.isInitial = true
        state.value.isFinished = false
        next()
    }

    func next() {
        guard !state.value.isLoading && !state.value.isFinished else {
            return
        }
        state.value.isLoading = true
        apiClient.request(E.self, uri: uri) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                if self.state.value.isInitial {
                    self.state.value.isInitial = false
                    self.notify(.initial(response))
                } else {
                    self.notify(.next(response))
                }
                self.state.value.isLoading = false
                let metadata = response.metadata
                guard (metadata.page + 1) * metadata.per < metadata.total else {
                    self.state.value.isFinished = true
                    return
                }
                self.uri.page = metadata.page + 1
            case .failure(let error):
                self.notify(.error(error))
            }
        }
    }
}

import Combine
import Foundation

extension PaginationRequest {
    private final class ItemsInner<Downstream: Subscriber>: Combine.Subscription where
        Downstream.Input == [E.Response.Item],
        Downstream.Failure == Never
    {
        private var downstream: Downstream?
        private let pagination: PaginationRequest
        private var currentDemand: Subscribers.Demand = .none

        init(downstream: Downstream, pagination: PaginationRequest) {
            self.downstream = downstream
            self.pagination = pagination

            var items = [E.Response.Item]()
            pagination.subscribe { [weak self] event in
                guard let self = self else { return }
                guard self.currentDemand > 0 else { return }
                switch event {
                case .initial(let response):
                    items = response.items
                    self.currentDemand += self.downstream?.receive(items) ?? .none
                    self.currentDemand -= 1
                case .next(let response):
                    items += response.items
                    self.currentDemand += self.downstream?.receive(items) ?? .none
                    self.currentDemand -= 1
                case .error: break
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            currentDemand += demand
        }

        func cancel() {
            downstream = nil
        }
    }

    struct ItemsPublisher: Combine.Publisher {
        typealias Output = [E.Response.Item]
        typealias Failure = Never

        let pagination: PaginationRequest
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: ItemsInner(downstream: subscriber, pagination: pagination))
        }
    }
    func items() -> ItemsPublisher {
        return ItemsPublisher(pagination: self)
    }

    private final class ErrorsInner<Downstream: Subscriber>: Combine.Subscription where
        Downstream.Input == Error,
        Downstream.Failure == Never
    {
        private var downstream: Downstream?
        private let pagination: PaginationRequest
        private var currentDemand: Subscribers.Demand = .none

        init(downstream: Downstream, pagination: PaginationRequest) {
            self.downstream = downstream
            self.pagination = pagination

            pagination.subscribe { [weak self] event in
                guard let self = self else { return }
                guard self.currentDemand > 0 else { return }
                switch event {
                case .initial, .next: break
                case .error(let error):
                    self.currentDemand += self.downstream?.receive(error) ?? .none
                    self.currentDemand -= 1
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            currentDemand += demand
        }

        func cancel() {
            downstream = nil
        }
    }

    struct ErrorsPublisher: Combine.Publisher {
        typealias Output = Error
        typealias Failure = Never

        let pagination: PaginationRequest
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: ErrorsInner(downstream: subscriber, pagination: pagination))
        }
    }

    func errors() -> ErrorsPublisher {
        return ErrorsPublisher(pagination: self)
    }

    var isRefreshing: AnyPublisher<Bool, Never> {
        state.map { $0.isLoading && $0.isInitial }.eraseToAnyPublisher()
    }
}
