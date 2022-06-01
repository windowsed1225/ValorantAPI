import Foundation
import Protoquest
import HandyOperators

final actor AuthClient: Protoclient {
	let baseURL = BaseURLs.authAPI
	let urlSession: URLSession
	var accessToken: AccessToken?
	
	private(set) var sessionID: String? {
		get { cookie(named: "ssid") }
		set {
			if let id = newValue {
				setCookie(named: "ssid", to: id)
			}
		}
	}
	private(set) var tdid: String? {
		get { cookie(named: "tdid") }
		set {
			if let id = newValue {
				setCookie(named: "tdid", to: id)
			}
		}
	}
	
	init(sessionID: String? = nil, tdid: String? = nil, urlSessionOverride: URLSession? = nil) async {
		self.urlSession = urlSessionOverride ?? .init(
			configuration: .ephemeral,
			delegate: NoRedirectsDelegate.shared,
			delegateQueue: nil
		)
		self.sessionID = sessionID
		self.tdid = tdid
	}
	
	private func cookie(named name: String) -> String? {
		urlSession.configuration.httpCookieStorage!.cookies!
			.first { $0.name == name }?.value
	}
	
	private func setCookie(named name: String, to value: String) {
		urlSession.configuration.httpCookieStorage!.setCookie(.init(properties: [
			.name: name,
			.value: value,
			.path: "/",
			.domain: "auth.riotgames.com",
		])!)
	}
	
	let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
	}
	
	func setAccessToken(_ token: AccessToken) {
		self.accessToken = token
	}
	
	func addHeaders(to rawRequest: inout URLRequest) async {
		rawRequest.headers.authorization = accessToken?.encoded
	}
	
	private final class NoRedirectsDelegate: NSObject, URLSessionTaskDelegate {
		static let shared = NoRedirectsDelegate()
		
		func urlSession(
			_ session: URLSession,
			task: URLSessionTask,
			willPerformHTTPRedirection response: HTTPURLResponse,
			newRequest request: URLRequest
		) async -> URLRequest? {
			nil
		}
	}
}
