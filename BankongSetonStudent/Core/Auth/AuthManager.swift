import Foundation
import SwiftUI

// MARK: - AuthManager

@MainActor
final class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var studentName: String

    init() {
        // Restore session from Keychain on app launch
        isLoggedIn = KeychainHelper.read(forKey: "auth_token") != nil
        studentName = KeychainHelper.read(forKey: "student_name") ?? ""
    }

    // Called after successful login
    func login(token: String, student: Student) {
        KeychainHelper.save(token, forKey: "auth_token")
        KeychainHelper.save(student.studentId, forKey: "student_id")
        KeychainHelper.save(student.name, forKey: "student_name")
        studentName = student.name
        isLoggedIn = true
    }

    // Called from Settings → Logout button
    func logout(apiClient: APIClient) async {
        _ = try? await apiClient.logout()  // best-effort server logout
        clearAll()
    }

    // Called when any ViewModel catches APIError.cardLost
    func handleCardLost() {
        // Persist the isCardLost flag BEFORE clearing everything else
        KeychainHelper.save("true", forKey: "isCardLost")
        clearAll()
    }

    // MARK: - Private

    private func clearAll() {
        let keysToDelete = [
            "auth_token",
            "student_id",
            "student_name",
            "last_balance",
            "theme_mode",
            "isCardLost",
            "budget_alert_month",
            "budgetAlerted80",
            "budgetAlerted100"
        ]
        keysToDelete.forEach { KeychainHelper.delete(forKey: $0) }
        isLoggedIn = false
        studentName = ""
    }
}
