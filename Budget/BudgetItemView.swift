//
//  BudgetItemView.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI

struct BudgetItemView: View {
    @Environment(\.managedObjectContext) private var context
    
    @State var item: Item
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var refreshID = UUID()
        
    @State private var showingDeleteAlert = false
    @State private var transactionToModify: Transaction?
    @State private var showingAllTransactions = false
    
    private var transactions: [Transaction] {
//        if showingAllTransactions {
//            return item.budgetItem?.getTransactions() ?? item.getTransactions()
//        } else {
            return item.getTransactions()
//        }
    }
    
    var body: some View {
        List {
            Section {
                let budgeted = (item.amount! as Decimal).currencyFormatted
                let spending = item.totalSpent.currencyFormatted
                let balance = item.totalRemaining.currencyFormatted
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Budgeted: \(budgeted)")
                        Text("Spending: \(spending)")
                        Text("Transactions: \(transactions.count)")
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Balance")
                        Text(balance)
                            .font(.largeTitle)
                            .foregroundColor(item.totalRemaining >= 0 ? .green : .red)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                }
                
            }
            
            Section {
                ForEach(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.name)
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
                    .contextMenu {
                        Button("Edit") {
                            transactionToModify = transaction
                            showingEditSheet = true
                        }
                        Button("Delete", role: .destructive) {
                            transactionToModify = transaction
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            
            
        }
        .navigationTitle(item.name ?? "Error")
        .sheet(isPresented: $showingCreateSheet) {
            CreateTransactionView(item: item)
                .onDisappear {
                    
                    refreshID = UUID()
                }
        }
        .sheet(isPresented: $showingEditSheet) {
            CreateTransactionView(item: item, editingTransaction: transactionToModify)
                .onDisappear {
                    refreshID = UUID()
                    transactionToModify = nil
                }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert, presenting: transactionToModify) { transaction in
            Button("Delete", role: .destructive) {
                deleteTransaction(transaction: transaction)
            }
            Button("Cancel", role: .cancel) {}
        } message: { transaction in
            Text("Are you sure you want to delete the transaction of \(currencyFormatter.string(from: transaction.amount!)!), paid to \(transaction.name)?")
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func deleteTransaction(transaction: Transaction) {
        withAnimation {
            Transaction.delete(transaction: transaction)
            transactionToModify = nil
        }
    }
}
