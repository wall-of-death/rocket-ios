//
//  APIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import Endpoint
import Foundation
import Combine

protocol APITokenProvider {
    func provideIdToken(_: @escaping (Result<String, Error>) -> Void)
}

class APIClient {
    private let baseURL: URL
    private let tokenProvider: APITokenProvider
    private let session: URLSession
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(baseUrl: URL, tokenProvider: APITokenProvider, session: URLSession = .shared) {
        self.baseURL = baseUrl
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) where E.Request == Endpoint.Empty {
        request(E.self, request: Endpoint.Empty(), uri: uri, file: file, line: line, callback: callback)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        let url: URL
        do {
            url = try uri.encode(baseURL: baseURL)
        } catch {
            callback(.failure(error))
            return
        }

        tokenProvider.provideIdToken { [unowned self] result in
            switch result {
            case .success(let idToken):
                self.request(
                    endpoint, request: request, url: url, idToken: idToken, file: file, line: line, callback: callback)
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    private func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, url: URL, idToken: String, file: StaticString, line: UInt,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        print(url)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        if E.method != .get {
            urlRequest.httpBody = try! encoder.encode(request)
        }

        let task = session.dataTask(with: urlRequest) { [decoder] (data, response, error) in
            if let error = error {
                callback(.failure(error))
                return
            }
            guard let data = data else {
                fatalError("URLSession.dataTask should provide either response or error")
            }

            do {

                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        let response: E.Response = try decoder.decode(E.Response.self, from: data)
                        callback(.success(response))
                    } else {
                        print("error response: \(httpResponse.statusCode)")
                        let errorMessage = String(data: data, encoding: .utf8)
                        callback(
                            .failure(
                                APIError.invalidStatus(
                                    "status: \(httpResponse.statusCode), message: \(String(describing: errorMessage))"))
                        )
                        print()
                    }
                }
            } catch let error {
                print("\(file):\(line): \(E.self) \(error)")
                callback(.failure(error))
                return
            }
        }
        task.resume()
    }
}


// MARK: - Combine Extensions
extension APIClient {
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> Future<E.Response, Error>
    where E.Request == Endpoint.Empty {
        request(endpoint, request: Endpoint.Empty(), uri: uri, file: file, line: line)
    }
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> Future<E.Response, Error> {
        return Future { promise in
            self.request(endpoint, request: request, uri: uri, file: file, line: line, callback: promise)
        }
    }
}