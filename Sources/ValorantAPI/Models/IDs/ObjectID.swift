import Foundation
import HandyOperators

public protocol ObjectIDProtocol: Hashable {
	associatedtype RawID: Hashable
	
	var rawID: RawID { get }
	
	init(rawID: RawID)
}

public struct ObjectID<Object, RawID: Hashable>: ObjectIDProtocol {
	public var rawID: RawID
	
	public init(rawID: RawID) {
		self.rawID = rawID
	}
}

extension ObjectID where RawID == LowercaseUUID {
	public init() {
		self.init(rawID: .init())
	}
}

extension ObjectID: Codable where RawID: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.init(rawID: try container.decode(RawID.self))
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawID)
	}
}

extension ObjectID: LosslessStringConvertible & CustomStringConvertible
where RawID: LosslessStringConvertible {
	public var description: String {
		rawID.description
	}
	
	public init?(_ description: String) {
		guard let rawID = RawID(description) else { return nil }
		self.init(rawID: rawID)
	}
}

extension ObjectID: CodingKeyRepresentable where RawID: CodingKeyRepresentable {
	public var codingKey: CodingKey {
		rawID.codingKey
	}
	
	public init?<T>(codingKey: T) where T: CodingKey {
		guard let rawID = RawID(codingKey: codingKey) else { return nil }
		self.init(rawID: rawID)
	}
}

// MARK: - Various Marker Types for API Concepts

/// you're probably looking for `MatchDetails` or `CompetitiveUpdate`
public enum Match {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public enum PlayerCard {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public enum PlayerTitle {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public enum Armor {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}
