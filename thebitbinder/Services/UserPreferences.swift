import Foundation

@MainActor
final class UserPreferences: ObservableObject {
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

    init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "there"
    }
}
