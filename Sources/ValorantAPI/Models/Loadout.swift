import Foundation
import Protoquest

extension ValorantClient {
	public func getLoadout() async throws -> Loadout {
		try await send(LoadoutRequest(playerID: userID))
	}
	
	public func updateLoadout(to loadout: Loadout) async throws -> Loadout {
		try await send(LoadoutUpdateRequest(playerID: userID, loadout: loadout))
	}
	
	struct LoadoutRequest: GetJSONRequest {
		var playerID: Player.ID
		
		var path: String {
			"/personalization/v2/players/\(playerID)/playerloadout"
		}
		
		typealias Response = Loadout
	}
	
	struct LoadoutUpdateRequest: JSONJSONRequest {
		var playerID: Player.ID
		var loadout: Loadout
		
		var body: Loadout { loadout }
		var httpMethod: String { "PUT" }
		
		var path: String {
			"/personalization/v2/players/\(playerID)/playerloadout"
		}
		
		typealias Response = Loadout
	}
}

public struct Loadout: Codable {
	public var subject: User.ID
	/// incremented every time the loadout is changed
	public var version: Int
	public var isIncognito: Bool
	public var identity: Identity
	public var guns: [Gun]
	public var sprays: [EquippedSpray]
	
	private enum CodingKeys: String, CodingKey {
		case subject = "Subject"
		case version = "Version"
		case identity = "Identity"
		case guns = "Guns"
		case sprays = "Sprays"
		case isIncognito = "Incognito"
	}
	
	public struct Gun: Codable {
		public var id: Weapon.ID
		public var skin: Skin
		public var buddy: Buddy?
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			id = try container.decodeValue(forKey: .id)
			
			let nested = try decoder.singleValueContainer()
			skin = try nested.decode(Skin.self)
			buddy = container.allKeys.contains(.buddyID) ? try nested.decode(Buddy.self) : nil
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(id, forKey: .id)
			
			try skin.encode(to: encoder)
			try buddy?.encode(to: encoder)
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "ID"
			case buddyID = "CharmID"
		}
		
		public struct Skin: Codable {
			public var skin: Weapon.Skin.ID
			public var level: Weapon.Skin.Level.ID
			public var chroma: Weapon.Skin.Chroma.ID
			
			private enum CodingKeys: String, CodingKey {
				case skin = "SkinID"
				case level = "SkinLevelID"
				case chroma = "ChromaID"
			}
		}
		
		public struct Buddy: Codable {
			public var buddy: Weapon.Buddy.ID
			public var level: Weapon.Buddy.Level.ID
			public var instance: Weapon.Buddy.Instance.ID
			
			private enum CodingKeys: String, CodingKey {
				case buddy = "CharmID"
				case level = "CharmLevelID"
				case instance = "CharmInstanceID"
			}
		}
	}
	
	public struct EquippedSpray: Codable {
		public var slot: Spray.Slot.ID
		public var spray: Spray.ID
		
		private enum CodingKeys: String, CodingKey {
			case slot = "EquipSlotID"
			case spray = "SprayID"
		}
	}
	
	public struct Identity: Codable {
		public var card: PlayerCard.ID
		public var title: PlayerTitle.ID
		private var levelBorder: LowercaseUUID
		public var isLevelHidden: Bool
		
		private enum CodingKeys: String, CodingKey {
			case card = "PlayerCardID"
			case title = "PlayerTitleID"
			case levelBorder = "PreferredLevelBorderID"
			case isLevelHidden = "HideAccountLevel"
		}
	}
}
