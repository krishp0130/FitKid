import Foundation

enum UserRole: String, Codable {
    case parent = "PARENT"
    case child = "CHILD"
}

struct User: Codable, Identifiable {
    let id: String
    var username: String
    var email: String?
    var role: UserRole
    var familyId: String
    var currentCreditScore: Int
    var profileImageURL: String?
    
    // For children only
    var parentCode: String?
    
    // Mock data
    static var mockChild = User(
        id: UUID().uuidString,
        username: "Alex",
        email: "alex@kidzone.com",
        role: .child,
        familyId: "family-1",
        currentCreditScore: 712,
        parentCode: "ABC123"
    )
    
    static var mockParent = User(
        id: UUID().uuidString,
        username: "Mom",
        email: "mom@kidzone.com",
        role: .parent,
        familyId: "family-1",
        currentCreditScore: 850,
        parentCode: "ABC123"
    )
}
