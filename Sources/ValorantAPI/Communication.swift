import Foundation
import HandyOperators
import ArrayBuilder

enum BaseURLs {
	static let auth = URL(string: "https://auth.riotgames.com")!
	static let authAPI = auth.appendingPathComponent("api/v1")
	static let entitlements = URL(string: "https://entitlements.auth.riotgames.com/api")!
	
	static func gameAPI(region: Region) -> URL {
		URL(string: "https://pd.\(region.subdomain).a.pvp.net")!
	}
}

protocol Request {
	func url(for client: Client) -> URL
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws
	
	associatedtype Response
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response
	
	@ArrayBuilder<URLParameter>
	func urlParams() -> [URLParameter]
}

// moving this inside currently crashes the compiler!
typealias URLParameter = (name: String, value: Any?)
protocol GameAPIRequest: Request {
	var path: String { get }
}

extension Request {
	func urlParams() -> [URLParameter] { [] }
}

extension GameAPIRequest {
	func url(for client: Client) -> URL {
		BaseURLs.gameAPI(region: client.region)
			.appendingPathComponent(path)
	}
}

typealias GetJSONRequest = GetRequest & JSONDecodingRequest
typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest

// MARK: - Request Encoding

protocol GetRequest: Request {}

extension GetRequest {
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {}
}

protocol JSONEncodingRequest: Request where Self: Encodable {
	static var httpMethod: String { get }
}

extension JSONEncodingRequest {
	static var httpMethod: String { "POST" }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpMethod = Self.httpMethod
		rawRequest.httpBody = try encoder.encode(self)
		rawRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
	}
}

// MARK: - Response Decoding

protocol JSONDecodingRequest: Request where Response: Decodable {}

extension JSONDecodingRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response {
		do {
			return try decoder.decode(Response.self, from: raw)
		} catch let error as DecodingError {
			throw JSONDecodingError(error: error, toDecode: raw)
		}
	}
}

protocol RawDataRequest: Request where Response == Data {}

extension RawDataRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response { raw }
}

protocol StringDecodingRequest: Request where Response == String {}

extension StringDecodingRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response {
		String(bytes: raw, encoding: .utf8)!
	}
}

private struct JSONDecodingError: LocalizedError {
	var error: DecodingError
	var toDecode: Data
	
	var errorDescription: String? {
		"""
		\(error.localizedDescription)
		
		\("" <- { dump(error, to: &$0) })
		
		The data to decode was:
		\(String(bytes: toDecode, encoding: .utf8)!)
		"""
	}
}
