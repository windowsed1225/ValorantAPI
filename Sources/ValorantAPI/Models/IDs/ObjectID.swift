import Foundation
import HandyOperators

public struct ObjectID<Object, RawValue>: Hashable, _RawWrapper where RawValue: Hashable {
	public var rawValue: RawValue
	
	public init(_ rawValue: RawValue) {
		self.rawValue = rawValue
	}
}

extension ObjectID where RawValue == UUID {
	var apiValue: String {
		rawValue.uuidString.lowercased()
	}
	
	public init() {
		self.rawValue = UUID()
	}
}

extension ObjectID: Codable where RawValue: Codable {}

extension ObjectID: CustomStringConvertible {
	public var description: String {
		String(describing: rawValue)
	}
}

// MARK: - Various Marker Types for API Concepts

public enum Season {
	public typealias ID = ObjectID<Self, UUID>
}

/// you're probably looking for `MatchDetails` or `CompetitiveUpdate`
public enum Match {
	public typealias ID = ObjectID<Self, UUID>
}

public enum Party {
	public typealias ID = ObjectID<Self, UUID>
}

public enum Agent {
	public typealias ID = ObjectID<Self, UUID>
}

public enum PlayerCard {
	public typealias ID = ObjectID<Self, UUID>
}

public enum PlayerTitle {
	public typealias ID = ObjectID<Self, UUID>
}

public enum Weapon {
	public typealias ID = ObjectID<Self, UUID>
}

public enum Armor {
	public typealias ID = ObjectID<Self, UUID>
}
