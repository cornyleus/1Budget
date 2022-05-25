//
//  PayeeView.swift
//  Budget
//
//  Created by Cory Iley on 4/26/22.
//

import SwiftUI

struct PayeeView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State var payee: Payee
    
    @State var editMode = false
    @State private var newName: String = ""
    @State private var alreadyExistsWarning = false
    @State private var showingDeleteWarning = false
    @State private var showingTransactions = false
    
    var body: some View {
        List {
            if editMode {
                Section {
                    TextField("New Name", text: $newName)
                }
            }
            
            Section {
                let spending = payee.totalSpent().currencyFormatted
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Transactions")
                        Button {
                            withAnimation {
                                showingTransactions.toggle()
                            }
                        } label: {
                            Text("\(payee.transactionsArray.count)")
                                .font(.largeTitle)
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Spending")
                        Text(spending)
                            .font(.largeTitle)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                }
                
            }
            
            if showingTransactions {
                Section {
                    ForEach(payee.transactionsArray) { transaction in
                        TransactionListRow(transaction: transaction, displaying: .item)
                    }
                }
            }
            
            Section {
                Button("Delete", role: .destructive) {
                    showingDeleteWarning = true
                }
            }
        }
        .navigationTitle(payee.name ?? "Error")
        .alert("Payee Already Exists", isPresented: $alreadyExistsWarning, presenting: payee) { payee in
            Button("Yes") {
                payee.edit(name: newName, in: context)
                withAnimation {
                    editMode = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { payee in
            if let existingPayee = Payee.alreadyExists(name: newName, in: context) {
                if let currentPayeeTransactions = payee.transactions, let oldPayeeTransactions = existingPayee.transactions {
                    let totalNumberOfTransactions = currentPayeeTransactions.count + oldPayeeTransactions.count
                    Text("Payee with the name \(newName) already exists.  Would you like to merge the two, combining \(totalNumberOfTransactions) transactions?")
                }
            }
        }
        .alert("Delete Payee", isPresented: $showingDeleteWarning, presenting: payee) { payee in
            Button("Delete", role: .destructive) {
                if Payee.delete(payee: payee) {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { payee in
            let transactionCount = payee.transactionsArray.count
            Text("Are you sure you want to delete \(payee.name!)?  \(transactionCount) total transactions will also be deleted.")
        }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !editMode {
                    Button("Edit") {
                        withAnimation {
                            editMode = true
                        }
                    }
                } else {
                    Button("Save") {
                        withAnimation {
                            saveChanges()
                        }
                    }
                }
            }
        }
    }
    
    /// Validate and update name of payee or merge into existing if necessary
    private func saveChanges() {
        if newName != "" {
            if let existingPayee = Payee.alreadyExists(name: newName, in: context) {
                alreadyExistsWarning = true
            } else {
                // edit name
                payee.edit(name: newName, in: context)
                editMode = false
            }
        }
    }
}
