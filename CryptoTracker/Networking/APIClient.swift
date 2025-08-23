//
//  APIClient.swift
//  CryptoTracker
//
//  Created by Jesus on 22/8/25.
//

import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ type: T.Type, endpoint: Endpoint) async throws -> T
}

struct APIError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func send<T: Decodable>(_ type: T.Type, endpoint: Endpoint) async throws -> T {
        var req = endpoint.urlRequest
        req.httpMethod = "GET"
        req.timeoutInterval = 30

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw APIError(message: "HTTP \(code) – \(body)")
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError(message: "Decoding error: \(error.localizedDescription)") }
    }
}
