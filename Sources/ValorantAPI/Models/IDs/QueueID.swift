import Foundation
import HandyOperators

public struct QueueID: SimpleRawWrapper {
	public static let unrated = Self("unrated")
	public static let competitive = Self("competitive")
	public static let spikeRush = Self("spikerush")
	public static let deathmatch = Self("deathmatch")
	public static let escalation = Self("ggteam")
	public static let snowballFight = Self("snowball")
	public static let custom = Self("custom")
	
	public var rawValue: String
	
	public init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}
