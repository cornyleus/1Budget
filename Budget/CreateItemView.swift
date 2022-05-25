//
//  CreateItemView.swift
//  Budget
//
//  Created by Cory Iley on 3/15/22.
//

import SwiftUI

class CreateItemViewModel: ObservableObject {
    @Published var name = ""
    @Published var amount = ""
    @Published var month: Month?
    @Published var category: Category?
    
    func loadData(item: Item) {
        name = item.name ?? ""
        amount = currencyFormatter.string(from: item.amount ?? 0) ?? "0"
        month = item.month
        if category == nil {
            category = item.category
        }
    }
    
    func load(month: Month) {
        self.month = month
    }
    
    func load(category: Category) {
        self.category = category
    }
    
    func isValid() -> Bool {
        return Item.validate(name: name, amount: amount)
    }
}


struct CreateItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var categories: FetchedResults<Category>
    @EnvironmentObject private var navController: NavController
    
    @State var editingItem: Item? = nil
    @State var editingCategory: Category? = nil

    @StateObject private var viewModel = CreateItemViewModel()
    
    @State private var showingDeleteAlert = false
        
    private var title: String {
        if editingItem != nil {
            return "Editing Budget Item"
        } else {
            return "New Budget Item"
        }
    }
    
    enum Field {
        case title
    }
    
    @FocusState private var focusedField: Field?
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(viewModel.month?.description ?? Month.current(in: context).description)
                }
                
                Section {
                    // hacky but somehow necessary to pre-load textfields
                    ForEach(0..<1) { _ in
                        TextField("Title", text: $viewModel.name)
                            .focused($focusedField, equals: .title)
                        TextField("Amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }
                    NavigationLink {
                        CategorySelectionView(selectedCategory: $viewModel.category)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(viewModel.category?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(editingItem == nil ? "Create" : "Save") {
                        if viewModel.isValid() {
                            let category = viewModel.category ?? categories.first!
                            let decimalAmount = Decimal(string: viewModel.amount.removeFormatAmount()) ?? 0
                            let month = viewModel.month ?? Month.current(in: context)
                            if let editingItem = editingItem {
                                editingItem.edit(name: viewModel.name, amount: decimalAmount, category: category, month: month, in: context)
                            } else {
                                let templateItem = Item.createTemplateItem(context: context, category: category, name: viewModel.name)
                                Item.createItem(in: month, templateItem: templateItem, amount: decimalAmount, seedMonths: true, context: context)
                            }
                            dismiss()
                        }
                    }
                }
                
                if editingItem != nil {
                    Section {
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(title)
            .alert("Delete Budget Item", isPresented: $showingDeleteAlert, presenting: editingItem) { item in
                Button("Delete", role: .destructive) {
                    if let templateItem = item.templateItem {
                        if Item.delete(item: templateItem) {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                if let templateItem = item.templateItem, let itemName = item.name {
                    Text("Are you sure you want to delete \(itemName)?  All \(templateItem.getTransactions().count) associated transactions will be deleted.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
        .onAppear {
            if let editingItem = editingItem {
                viewModel.loadData(item: editingItem)
            } else if let month = navController.selectedMonth {
                viewModel.load(month: month)
                viewModel.load(category: editingCategory ?? Category.getNoneCategory(context: context))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focusedField = .title
                }
            }
            
        }
    }
}

struct CreateItemView_Previews: PreviewProvider {
    static var previews: some View {
        CreateItemView()
    }
}
