import Foundation

public enum GameMode {
	public struct ID: SimpleRawWrapper {
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let decoded = try container.decode(String.self)
			// e.g. "Game/GameModes/Bomb/BombGameMode.BombGameMode_C"
			
			let pathPrefix = "/Game/"
			guard decoded.hasPrefix(pathPrefix) else { self.init(decoded); return }
			let trimmed = decoded.dropFirst(pathPrefix.count)
			// e.g. "GameModes/Bomb/BombGameMode.BombGameMode_C"
			
			let parts = trimmed.split(separator: ".")
			assert(parts.count == 2)
			self.init(String(parts.first!))
			// e.g. "GameModes/Bomb/BombGameMode"
		}
	}
}
