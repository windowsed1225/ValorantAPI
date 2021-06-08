import Foundation
import Combine
import HandyOperators
import Protoquest

public final class ValorantClient: Identifiable, Codable {
	/// The decoder used to decode JSON data received from Riot's servers.
	public static let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .iso8601OrTimestamp
		$0.userInfo[.isDecodingFromRiot] = true
	}
	
	/// There's no real point for typed errors most of the time.
	public typealias BasicPublisher<T> = AnyPublisher<T, Error>
	
	/// Attempts to authenticate with the given credentials and, as a result, publishes a client instance initialized with the necessary tokens.
	public static func authenticated(username: String, password: String, region: Region) -> BasicPublisher<ValorantClient> {
		Client.authenticated(username: username, password: password, region: region)
			.map(Self.init(client:))
			.eraseToAnyPublisher()
	}
	
	private let client: Client
	
	private init(client: Client) {
		self.client = client
	}
	
	func send<R: Request>(_ request: R) -> BasicPublisher<R.Response> {
		client.send(request)
	}
	
	public func setClientVersion(_ version: String) {
		client.clientVersion = version
	}
	
	/// An error received from Riot's API.
	public enum APIError: Error {
		/// This is outputted for 401 error codes, which the API sometimes responds with instead of providing actual error information… It usually also means you need to reauthenticate.
		case unauthorized
		/// This likely means your access token has expired.
		case tokenFailure(message: String)
		/// The service is currently down for scheduled maintenance.
		case scheduledDowntime(message: String)
		/// A non-200 response code was received. If the API returned a valid error JSON, the provided error is passed on here.
		case badResponseCode(Int, Protoresponse, RiotError?)
		/// You were rate-limited for sending too many requests. If provided, `retryAfter` indicates after how many seconds the limit should be lifted again.
		case rateLimited(retryAfter: Int?)
	}
}

/// How Riot's API represents an error it encountered.
public struct RiotError: Decodable {
	public var errorCode: String
	public var message: String
}

private final class Client: Identifiable, Protoclient, Codable {
	typealias APIError = ValorantClient.APIError
	
	static let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	var requestEncoder: JSONEncoder { Self.requestEncoder }
	
	var responseDecoder: JSONDecoder { ValorantClient.responseDecoder }
	
	let region: Region
	let session = URLSession(configuration: .ephemeral)
	
	fileprivate var accessToken: String?
	fileprivate var entitlementsToken: String?
	fileprivate var clientVersion: String?
	
	var baseURL: URL { BaseURLs.gameAPI(region: region) }
	
	static func authenticated(username: String, password: String, region: Region) -> AnyPublisher<Client, Error> {
		let client = Client(region: region)
		return client.establishSession()
			.flatMap {
				client.getAccessToken(username: username, password: password)
					.map { client.accessToken = $0 }
			}
			.flatMap {
				client.getEntitlementsToken()
					.map { client.entitlementsToken = $0 }
			}
			.map { client }
			.eraseToAnyPublisher()
	}
	
	private init(region: Region) {
		self.region = region
	}
	
	private static let encodedPlatformInfo = try! JSONEncoder()
		.encode(PlatformInfo.supportedExample)
		.base64EncodedString()
	
	func addHeaders(to rawRequest: inout URLRequest) {
		if let token = accessToken {
			rawRequest.setValue(token, forHTTPHeaderField: "Authorization")
		}
		if let token = entitlementsToken {
			rawRequest.setValue(token, forHTTPHeaderField: "X-Riot-Entitlements-JWT")
		}
		if let version = clientVersion {
			rawRequest.setValue(version, forHTTPHeaderField: "X-Riot-ClientVersion")
		}
		rawRequest.setValue(Self.encodedPlatformInfo, forHTTPHeaderField: "X-Riot-ClientPlatform")
	}
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) -> BasicPublisher<Protoresponse> {
		session.dataTaskPublisher(for: rawRequest)
			.mapError { $0 }
			.map(wrapResponse(data:response:))
			.tryMap { response in
				let code = response.httpMetadata!.statusCode
				guard code != 200 else { return response }
				
				if let error = try? response.decodeJSON(as: RiotError.self) {
					switch error.errorCode {
					case "BAD_CLAIMS":
						throw APIError.tokenFailure(message: error.message)
					case "SCHEDULED_DOWNTIME":
						throw APIError.scheduledDowntime(message: error.message)
					default:
						throw APIError.badResponseCode(code, response, error)
					}
				} else {
					switch code {
					case 401:
						throw APIError.unauthorized
					case 429:
						throw APIError.rateLimited(
							retryAfter: response.httpMetadata!
								.value(forHTTPHeaderField: "Retry-After")
								.flatMap(Int.init)
						)
					default:
						throw APIError.badResponseCode(code, response, nil)
					}
				}
			}
			.eraseToAnyPublisher()
	}
	
	#if DEBUG
	func traceOutgoing<R>(_ rawRequest: URLRequest, for request: R) where R : Request {
		print("sending request to", rawRequest.url!)
	}
	#endif
	
	private enum CodingKeys: CodingKey {
		case region
		case accessToken
		case entitlementsToken
		case clientVersion
	}
}

private extension CodingUserInfoKey {
	static var isDecodingFromRiot = Self(rawValue: "isDecodingFromRiot")!
}

extension Decoder {
	var isDecodingFromRiot: Bool {
		(userInfo[.isDecodingFromRiot] as? Bool) ?? false
	}
}

enum BaseURLs {
	static let auth = URL(string: "https://auth.riotgames.com")!
	static let authAPI = auth.appendingPathComponent("api/v1")
	static let entitlements = URL(string: "https://entitlements.auth.riotgames.com/api")!
	
	static func gameAPI(region: Region) -> URL {
		URL(string: "https://pd.\(region.subdomain).a.pvp.net")!
	}
}

private extension JSONDecoder.DateDecodingStrategy {
	static let iso8601OrTimestamp = custom { decoder in
		let container = try decoder.singleValueContainer()
		return try nil
			?? (try? Date(timeIntervalSince1970: container.decode(TimeInterval.self) / 1000))
			?? (try? formatter.date(from: container.decode(String.self)))
			??? DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Could not decode timestamp nor ISO-8601 date from value."
			)
	}
	
	private static let formatter = ISO8601DateFormatter()
}
