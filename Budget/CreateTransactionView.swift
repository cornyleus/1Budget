//
//  CreateTransactionView.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI

class CreateTransactionViewModel: ObservableObject {
    @Published var payee = ""
    @Published var amount = ""
    @Published var memo = ""
    @Published var date = Date()
    @Published var selectedPayee: Payee? {
        didSet {
            payee = selectedPayee?.name ?? ""
        }
    }
    @Published var selectedItem: Item? {
        didSet {
            if payee == "" {
                if let recentPayee = selectedItem?.mostRecentPayee() {
                    selectedPayee = recentPayee
                    payee = recentPayee.name ?? ""
                }
            }
        }
    }
    var loaded = false
    
    func loadData(transaction: Transaction) {
        if !loaded {
            payee = transaction.name
            amount = currencyFormatter.string(from: transaction.amount ?? 0) ?? "0"
            memo = transaction.memo ?? ""
            date = transaction.date!
            selectedItem = transaction.item
            selectedPayee = transaction.payee
            
            loaded = true
        }
    }
        
    var decimalAmount: NSDecimalNumber {
        NSDecimalNumber(string: amount.removeFormatAmount())
    }
    
    func isValidTransaction() -> Bool {
        var valid = true
        valid = Transaction.validate(name: payee, amount: amount)
        if selectedItem == nil {
            valid = false
        }
        return valid
    }
}

struct DateSelectionView: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            DatePicker("Select a date", selection: $date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .frame(maxHeight: 400)
            
            Section {
                Button("OK") {
                    dismiss()
                }
            }
            
        }
        .navigationTitle("Select Date")
    }
}

struct ItemSelectionView: View {
    @SectionedFetchRequest(sectionIdentifier: \.categoryName, sortDescriptors: [SortDescriptor(\.category!.number), SortDescriptor(\.number)], predicate: NSPredicate(format: "month == nil"), animation: .none) private var items: SectionedFetchResults<String, Item>
    @Binding var selectedItem: Item?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            ForEach(items) { category in
                let title = category.id == "None" ? "Uncategorized" : category.id
                Section(header: Text(title)) {
                    ForEach(category) { item in
                        Button {
                            selectedItem = item
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.name ?? "Error")
                                    .foregroundColor(.primary)
                                if item == selectedItem || item == selectedItem?.templateItem {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Budget Item")
    }
}

struct PayeeSelectionView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name!)]) private var payees: FetchedResults<Payee>
    @Binding var selectedPayee: Payee?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(payees) { payee in
                    Button {
                        selectedPayee = payee
                        dismiss()
                    } label: {
                        HStack {
                            Text(payee.name ?? "Error")
                                .foregroundColor(.primary)
                            if payee == selectedPayee {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Payee")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


struct CreateTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @EnvironmentObject private var navController: NavController
    
    @State var item: Item?
    var editingTransaction: Transaction?
    @StateObject private var viewModel = CreateTransactionViewModel()
    
    @State private var showingPayeeSelectionSheet = false
    @State private var showingInvalidAlert = false
    @State private var showingDeleteAlert = false
    
    enum Field {
        case amount, payee
    }
    
    @FocusState private var focusedField: Field?
    
    private var title: String {
        if editingTransaction == nil {
            return "New Transaction"
        } else {
            return "Edit Transaction"
        }
    }
        
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Amount", text: $viewModel.amount)
                        .focused($focusedField, equals: .amount)
                        .keyboardType(.decimalPad)
                    HStack {
                        TextField("Payee", text: $viewModel.payee)
                            .focused($focusedField, equals: .payee)
                        Button {
                            showingPayeeSelectionSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        
                    }
                    
                    
                    NavigationLink(destination: DateSelectionView(date: $viewModel.date)) {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(dateFormatter.string(from: viewModel.date))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: ItemSelectionView(selectedItem: $viewModel.selectedItem)) {
                        HStack {
                            Text("Budget Item")
                            Spacer()
                            Text(viewModel.selectedItem?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    TextField("Note (optional)", text: $viewModel.memo)
                }
                
                Section {
                    Button(editingTransaction == nil ? "Create" : "Save") {
                        if viewModel.isValidTransaction() {
                            if let editingTransaction = editingTransaction {
                                // edit
                                if let item = viewModel.selectedItem {
                                    editingTransaction.edit(context: context, item: item, name: viewModel.payee, amount: viewModel.decimalAmount as Decimal, memo: viewModel.memo, date: viewModel.date)
                                }
                            } else {
                                // create
                                if let item = viewModel.selectedItem {
                                    Transaction.createTransaction(context: context, item: item, name: viewModel.payee, amount: viewModel.decimalAmount as Decimal, memo: viewModel.memo, date: viewModel.date)
                                }
                            }
                            navController.loadMonths(context: context)
                            let month = Month.findOrCreate(date: viewModel.date, in: context)
                            navController.set(month: month)
                            dismiss()
                        } else {
                            showingInvalidAlert = true
                        }
                    }
                }
                
                if editingTransaction != nil {
                    Section {
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(title)
            .sheet(isPresented: $showingPayeeSelectionSheet) {
                PayeeSelectionView(selectedPayee: $viewModel.selectedPayee)
            }
            .alert("Invalid Transaction", isPresented: $showingInvalidAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Amount or Payee invalid")
            }
            .alert("Delete Transaction", isPresented: $showingDeleteAlert, presenting: editingTransaction) { transaction in
                Button("Delete", role: .destructive) {
                    if Transaction.delete(transaction: transaction) {
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { transaction in
                Text("Are you sure you want to delete the transaction of \(currencyFormatter.string(from: transaction.amount!)!), paid to \(transaction.name)?")
            }
            .onAppear {
                if let editingTransaction = editingTransaction {
                    viewModel.loadData(transaction: editingTransaction)
                } else {
                    if viewModel.selectedItem == nil, let item = item {
                        viewModel.selectedItem = item
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        focusedField = .amount
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
