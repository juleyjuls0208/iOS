import Foundation

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var limit: Double = 0
    @Published var spent: Double = 0
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""

    var percent: Double { limit > 0 ? min((spent / limit) * 100, 100) : 0 }

    func load(apiClient: APIClient, authManager: AuthManager) async {
        isLoading = true
        defer { isLoading = false }
        async let budgetResp = apiClient.getBudget()
        async let txResp = apiClient.getTransactions(limit: 200, offset: 0)
        do {
            let (budget, txs) = try await (budgetResp, txResp)
            limit = budget.monthlyLimit
            let prefix = currentMonthPrefix()
            spent = txs.transactions
                .filter { $0.timestamp.hasPrefix(prefix) }
                .filter { $0.type == "Purchase" || $0.type == "NFC Purchase" }
                .reduce(0) { $0 + $1.amount }
            checkAlerts()
        } catch APIError.cardLost {
            authManager.handleCardLost()
        } catch { /* swallow other errors — UI shows stale data */ }
    }

    func setBudget(limit newLimit: Double, apiClient: APIClient, authManager: AuthManager) async {
        do {
            let resp = try await apiClient.setBudget(monthlyLimit: newLimit)
            if resp.success {
                limit = resp.monthlyLimit
                checkAlerts()
            }
        } catch APIError.cardLost {
            authManager.handleCardLost()
        } catch {}
    }

    private func currentMonthPrefix() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    private func checkAlerts() {
        let alertMonth = KeychainHelper.read(forKey: "budget_alert_month")
        let thisMonth = currentMonthPrefix()
        if alertMonth != thisMonth {
            KeychainHelper.save(thisMonth, forKey: "budget_alert_month")
            KeychainHelper.delete(forKey: "budgetAlerted80")
            KeychainHelper.delete(forKey: "budgetAlerted100")
        }
        if percent >= 80 && KeychainHelper.read(forKey: "budgetAlerted80") == nil {
            KeychainHelper.save("true", forKey: "budgetAlerted80")
            alertMessage = "You've used 80% of your monthly budget"
            showAlert = true
        }
        if percent >= 100 && KeychainHelper.read(forKey: "budgetAlerted100") == nil {
            KeychainHelper.save("true", forKey: "budgetAlerted100")
            alertMessage = "You've exceeded your monthly budget"
            showAlert = true
        }
    }
}
