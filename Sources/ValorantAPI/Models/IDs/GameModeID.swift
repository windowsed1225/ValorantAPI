import Foundation

public struct GameModeID: SimpleRawWrapper {
	public var rawValue: String
	
	public init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}
