//
//  TransactionListRow.swift
//  Budget
//
//  Created by Cory Iley on 4/26/22.
//

import SwiftUI

struct TransactionListRow: View {
    enum DisplayType {
        case payee
        case item
    }
    
    @State var transaction: Transaction
    @State var displaying: DisplayType = .payee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(displaying == .payee ? transaction.name : transaction.item?.name ?? "Budget Item")
                        .font(.headline)
                    Text(dateFormatter.string(from: transaction.date!))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(currencyFormatter.string(from: transaction.amount!) ?? "Error")
            }
            if transaction.memo != "" {
                Text(transaction.memo ?? "Error")
                    .font(.caption)
            }
        }
    }
}
