import Foundation
import HandyOperators

public struct QueueID {
	public static let unrated = Self(rawValue: "unrated")
	public static let competitive = Self(rawValue: "competitive")
	public static let spikeRush = Self(rawValue: "spikerush")
	public static let deathmatch = Self(rawValue: "deathmatch")
	public static let escalation = Self(rawValue: "ggteam")
	public static let snowballFight = Self(rawValue: "snowball")
	public static let custom = Self(rawValue: "custom")
	
	public var rawValue: String
	
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}

extension QueueID: Codable {
	public init(from decoder: Decoder) throws {
		self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
	}
	
	public func encode(to encoder: Encoder) throws {
		try encoder.singleValueContainer() <- { try $0.encode(rawValue) }
	}
}
