import SwiftUI

// MARK: - ReceiptView
// Shows full receipt detail for a Purchase or NFC Purchase transaction.
// Falls back to a synthetic "NFC Payment" line item when items is nil/empty.

struct ReceiptView: View {
    let transaction: Transaction

    // MARK: - Computed display values

    var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy"
        if let date = parser.date(from: transaction.timestamp) {
            return display.string(from: date)
        }
        return transaction.timestamp
    }

    var formattedTime: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let display = DateFormatter()
        display.dateFormat = "h:mm a"
        if let date = parser.date(from: transaction.timestamp) {
            return display.string(from: date)
        }
        return ""
    }

    // MARK: - Line items with synthetic fallback

    var lineItems: [TransactionItem] {
        if let items = transaction.items, !items.isEmpty {
            return items
        }
        return [TransactionItem(name: "NFC Payment", price: transaction.amount, qty: 1)]
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Date", value: formattedDate)
                LabeledContent("Time", value: formattedTime)
                LabeledContent("Type", value: transaction.type)
                LabeledContent("Total", value: "₱\(String(format: "%.2f", transaction.amount))")
                LabeledContent("Balance Before", value: "₱\(String(format: "%.2f", transaction.balanceBefore))")
                LabeledContent("Balance After", value: "₱\(String(format: "%.2f", transaction.balance))")
            }

            Section("Items") {
                ForEach(lineItems, id: \.name) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("×\(item.qty)")
                            .foregroundColor(.secondary)
                        Text("₱\(String(format: "%.2f", item.price * Double(item.qty)))")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
