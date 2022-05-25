//
//  SpendingAndBalanceView.swift
//  Budget
//
//  Created by Cory Iley on 4/15/22.
//

import SwiftUI

struct SpendingAndBalanceView: View {
    @EnvironmentObject private var navController: NavController
    @State var month: Month? = nil
    @State var item: Item? = nil
    
    
    @State var budgeted: Decimal = 0
    @State var spending: Decimal = 0
    @State var balance: Decimal = 0
    @State var transactionCount = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Budgeted: \(budgeted.currencyFormatted)")
                Text("Spending: \(spending.currencyFormatted)")
                Text("Transactions: \(transactionCount)")
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Balance")
                Text(balance.currencyFormatted)
                    .font(.largeTitle)
                    .foregroundColor(balance >= 0 ? .green : .red)
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
            }
        }
        .onAppear {
            if let month = month {
                budgeted = month.totalBudgeted
                 spending = month.totalSpent
                 balance = month.totalBalance
            } else if let item = item {
                 budgeted = (item.amount! as Decimal)
                 spending = item.totalSpent
                 balance = item.totalRemaining
            }
        }
    }
}
