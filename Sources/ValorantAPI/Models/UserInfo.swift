import Foundation

public struct UserInfo: Codable {
	public var account: Account
	public var id: Player.ID
	
	public init(account: Account, id: Player.ID) {
		self.account = account
		self.id = id
	}
	
	private enum CodingKeys: String, CodingKey {
		case account = "acct"
		case id = "sub"
	}
	
	public struct Account: Codable {
		public var gameName: String
		public var tagLine: String
		public var createdAt: Date
		
		public init(gameName: String, tagLine: String, createdAt: Date) {
			self.gameName = gameName
			self.tagLine = tagLine
			self.createdAt = createdAt
		}
		
		public var name: String {
			"\(gameName) #\(tagLine)"
		}
	}
}
