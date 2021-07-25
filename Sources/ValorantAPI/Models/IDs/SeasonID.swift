import Foundation

public enum Season {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public extension Season.ID {
	static let closedBeta = Self("0df5adb9-4dcb-6899-1306-3e9860661dd3")!
	static let episode1 = Self("fcf2c8f4-4324-e50b-2e23-718e4a3ab046")!
	static let episode1Act1 = Self("3f61c772-4560-cd3f-5d3f-a7ab5abda6b3")!
	static let episode1Act2 = Self("0530b9c4-4980-f2ee-df5d-09864cd00542")!
	static let episode1Act3 = Self("46ea6166-4573-1128-9cea-60a15640059b")!
	static let episode2 = Self("71c81c67-4fae-ceb1-844c-aab2bb8710fa")!
	static let episode2Act1 = Self("97b6e739-44cc-ffa7-49ad-398ba502ceb0")!
	static let episode2Act2 = Self("ab57ef51-4e59-da91-cc8d-51a5a2b9b8ff")!
	static let episode2Act3 = Self("52e9749a-429b-7060-99fe-4595426a0cf7")!
	static let episode3 = Self("97b39124-46ce-8b55-8fd1-7cbf7ffe173f")!
	static let episode3Act1 = Self("2a27e5d2-4d30-c9e2-b15a-93b8909a442c")!
	static let episode3Act2 = Self("4cb622e1-4244-6da3-7276-8daaf1c01be2")!
	static let episode3Act3 = Self("a16955a5-4ad0-f761-5e9e-389df1c892fb")!
}
