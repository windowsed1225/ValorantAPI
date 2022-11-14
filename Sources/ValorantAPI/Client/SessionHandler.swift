import Foundation
import Combine
import HandyOperators

/// provides access to a session, refreshing as needed
final actor SessionHandler {
	private(set) var session: APISession {
		didSet {
			sessionSubject.send(session)
		}
	}
	let sessionSubject = PassthroughSubject<APISession, Never>()
	
	private let multifactorHandler: MultifactorHandler?
	private var isResumingSession = false
	private var waitingForSession: [CheckedContinuation<Void, Error>] = []
	
	init(
		session: APISession,
		multifactorHandler: MultifactorHandler? = nil
	) {
		self.session = session
		self.multifactorHandler = multifactorHandler
	}
	
	func getAccessToken() async throws -> AccessToken {
		if session.accessToken.hasExpired {
			let id = UUID()
			if isResumingSession {
				print(id, "waiting for resumption…")
				try await withCheckedThrowingContinuation {
					waitingForSession.append($0)
				}
				print(id, "waiting complete!")
			} else {
				print(id, "resuming session")
				try await refreshAccessToken()
				print(id, "session resumed!")
			}
		}
		
		return session.accessToken
	}
	
	private func refreshAccessToken() async throws {
		assert(!isResumingSession)
		isResumingSession = true
		defer {
			isResumingSession = false
			waitingForSession = []
		}
		
		do {
			do {
				session = try await session <- {
					try await $0.refreshAccessToken(
						multifactorHandler: multifactorHandler ?? { _ in
							self.session.hasExpired = true
							throw APIError.sessionExpired
						}
					)
				}
				
				waitingForSession.forEach { $0.resume() }
			} catch {
				waitingForSession.forEach { $0.resume(throwing: error) }
				throw error
			}
		} catch {
			throw APIError.sessionResumptionFailure(error)
		}
	}
}
