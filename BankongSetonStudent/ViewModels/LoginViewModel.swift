import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var studentId: String = ""
    @Published var pin: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    var canSubmit: Bool {
        !studentId.trimmingCharacters(in: .whitespaces).isEmpty &&
        pin.count >= 4 &&
        !isLoading
    }

    func login(apiClient: APIClient, authManager: AuthManager) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await apiClient.login(
                studentId: studentId.trimmingCharacters(in: .whitespaces),
                pin: pin
            )
            authManager.login(token: response.token, student: response.student)
        } catch APIError.unauthorized {
            errorMessage = "Invalid student ID or PIN. Please try again."
        } catch APIError.httpError(let code) {
            errorMessage = "Server error (\(code)). Please try again later."
        } catch {
            errorMessage = "Network error. Check your connection and try again."
        }
    }
}
