import Foundation
import Protoquest
import HandyOperators

struct AuthClient {
	let baseURL = BaseURLs.authAPI
	let urlSession: URLSession
	var accessToken: AccessToken?
	
	init(urlSessionOverride: URLSession? = nil) async {
		self.urlSession = urlSessionOverride ?? .init(configuration: .ephemeral)
	}
	
	func cookies() -> [HTTPCookie] {
		urlSession.configuration.httpCookieStorage!.cookies ?? []
	}
	
	func setCookies(_ cookies: [HTTPCookie]) {
		cookies.forEach(urlSession.configuration.httpCookieStorage!.setCookie(_:))
	}
	
	func clearCookies() {
		urlSession.configuration.httpCookieStorage!.removeCookies(since: .distantPast)
	}
	
	func addHeaders(to rawRequest: inout URLRequest) async {
		rawRequest.headers.authorization = accessToken?.encoded
	}
	
	func send<R: AuthRequest>(_ request: R) async throws -> R.Response {
		let urlRequest = try URLRequest(url: request.url(relativeTo: BaseURLs.authAPI)) <- {
			try request.configure(&$0)
			$0.headers.authorization = accessToken?.encoded
		}
		
		let response = try await Protolayer.urlSession(urlSession)
			.send(urlRequest)
		
		return try request.decodeResponse(from: response)
	}
}

protocol AuthRequest: Request {}

extension JSONEncodingRequest where Self: AuthRequest {
	var encoderOverride: JSONEncoder? { requestEncoder }
}

extension JSONDecodingRequest where Self: AuthRequest {
	var decoderOverride: JSONDecoder? { responseDecoder }
}

private let requestEncoder = JSONEncoder() <- {
	$0.keyEncodingStrategy = .convertToSnakeCase
}
private let responseDecoder = JSONDecoder() <- {
	$0.keyDecodingStrategy = .convertFromSnakeCase
}
