import Foundation
import Combine
import HandyOperators

public final class Client: Identifiable {
	let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .millisecondsSince1970
	}
	
	public let region: Region
	private let session = URLSession(configuration: .ephemeral)
	
	private var accessToken: String?
	private var entitlementsToken: String?
	
	public static func authenticated(username: String, password: String, region: Region) -> AnyPublisher<Client, Error> {
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
	
	func send<R: Request>(_ request: R) -> AnyPublisher<R.Response, Error> {
		Just(request)
			.tryMap(rawRequest(for:))
			.flatMap { [session] in
				session.dataTaskPublisher(for: $0).mapError { $0 }
			}
			//.map { $0 <- { print("response: \(String(bytes: $0.data, encoding: .utf8)!)") } }
			.tryMap { [responseDecoder] in
				try request.decodeResponse(from: $0.data, using: responseDecoder)
			}
			.eraseToAnyPublisher()
	}
	
	private func rawRequest<R: Request>(for request: R) throws -> URLRequest {
		let components = URLComponents(
			url: request.url(for: self),
			resolvingAgainstBaseURL: false
		)! <- {
			$0.queryItems = request.urlParams().map { name, value in
				URLQueryItem(
					name: name,
					value: value.map(String.init(describing:))
				)
			}
		}
		
		return try URLRequest(url: components.url!) <- { rawRequest in
			try request.encode(to: &rawRequest, using: requestEncoder)
			
			//print("sending request to \(request.url)")
			//rawRequest.httpBody.map { print("request: \(String(bytes: $0, encoding: .utf8)!)") }
			
			addHeaders(to: &rawRequest)
		}
	}
	
	private static let encodedPlatformInfo = try! JSONEncoder()
		.encode(PlatformInfo.supportedExample)
		.base64EncodedString()
	
	private func addHeaders(to rawRequest: inout URLRequest) {
		if let token = accessToken {
			rawRequest.setValue(token, forHTTPHeaderField: "Authorization")
		}
		if let token = entitlementsToken {
			rawRequest.setValue(token, forHTTPHeaderField: "X-Riot-Entitlements-JWT")
		}
		rawRequest.setValue(Self.encodedPlatformInfo, forHTTPHeaderField: "X-Riot-ClientPlatform")
	}
}
