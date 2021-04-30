import Foundation
import HandyOperators

public struct MapID {
	public var path: String
	
	public static let mapPaths: [(path: String, map: String)] = [
		("Bonsai", "split"),
		("Triad", "haven"),
		("Duality", "bind"),
		("Ascent", "ascent"),
		("Port", "icebox"),
		("Foxtrot", "breeze"),
	]
	.map { key, map in ("/Game/Maps/\(key)/\(key)", map) }
	
	private static let mapNames = Dictionary(uniqueKeysWithValues: mapPaths)
	
	public var mapName: String? {
		Self.mapNames[path]
	}
	
	public init(path: String) {
		self.path = path
	}
}

extension MapID: Codable {
	public init(from decoder: Decoder) throws {
		self.init(path: try decoder.singleValueContainer().decode(String.self))
	}
	
	public func encode(to encoder: Encoder) throws {
		try encoder.singleValueContainer() <- { try $0.encode(path) }
	}
}
