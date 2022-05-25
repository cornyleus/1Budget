//
//  ManageItemsView.swift
//  Budget
//
//  Created by Cory Iley on 3/13/22.
//

import SwiftUI

struct ManageBudgetView: View {
    @Environment(\.managedObjectContext) var context
    @SectionedFetchRequest(sectionIdentifier: \.categoryName, sortDescriptors: [SortDescriptor(\.category!.number), SortDescriptor(\.templateItem!.number)]) private var items: SectionedFetchResults<String, Item>
    @EnvironmentObject private var navController: NavController
    
    init(month: Month) {
        _items = SectionedFetchRequest<String, Item>(sectionIdentifier: \.categoryName, sortDescriptors: [SortDescriptor(\.category!.number), SortDescriptor(\.templateItem!.number)], predicate: NSPredicate(format: "month == %@", month))
        _month = State(initialValue: month)
    }
    
    @State private var editingItem: Item?
    @State private var newAmount = ""
    
    @State private var newItemCategory: Category? = nil
    @State private var movedCategory: Category? = nil
        
    @State private var showingManageCategoriesSheet = false
    @State private var showingManagePayeesSheet = false
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    
    @State private var showOnboardSheet = false
    
    enum Field {
        case amount
    }
    @FocusState private var focusedState: Field?
    
    @State var month: Month
    
    var title: String {
        month.description
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    PeriodSelectionView()
                }
                
                ForEach(items) { category in
                    let title = category.id == "None" ? "Uncategorized" : category.id
                    Section(
                        header:
                            HStack {
                                Text(title)
                                Button {
                                    newItemCategory = Category.findOrCreate(name: category.id, in: context)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                    ) {
                        ForEach(category) { item in
                            HStack {
                                if let editingItem = editingItem, editingItem == item {
                                    Text(editingItem.name ?? "Error")
                                    Spacer()
                                    TextField("Amount", text: $newAmount)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedState, equals: .amount)
                                        .fixedSize()
                                    Button {
                                        // save
                                        if Item.validate(amount: newAmount) {
                                            let decimalAmount = Decimal(string: newAmount.removeFormatAmount()) ?? 0
                                            item.edit(amount: decimalAmount, context: context)
                                            self.editingItem = nil
                                            newAmount = ""
                                        } else {
                                            self.editingItem = nil
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.square")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                } else {
                                    Button {
                                        newAmount = currencyFormatter.string(from: item.amount ?? 0) ?? "$0.00"
                                        showingEditSheet = true
                                        editingItem = item
                                    } label: {
                                        HStack {
                                            Text(item.name ?? "Error")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            let amount = currencyFormatter.string(from: (item.amount ?? 0) as NSDecimalNumber) ?? "Error"
                                            Group {
                                                Text(amount)
                                                    .foregroundColor(.secondary)
                                                Button {
                                                    editingItem = item
                                                    newAmount = ""
                                                    focusedState = nil
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                        focusedState = .amount
                                                    }
                                                } label: {
                                                    Image(systemName: "square.and.pencil")
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                            .onTapGesture {
                                                editingItem = item
                                                newAmount = ""
                                                focusedState = nil
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    focusedState = .amount
                                                }
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            .onDrag {
                                movedCategory = Category.findOrCreate(name: category.id, in: context)
                                return NSItemProvider()
                            }
                        }
                        .onMove(perform: move)
                    }
                    .headerProminence(.increased)
                }
            }
            .navigationTitle("Manage")
            .onChange(of: navController.selectedMonth ?? self.month) { month in
                withAnimation {
                    self.month = month
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingManageCategoriesSheet = true
                        } label: {
                            Label("Categories", systemImage: "list.bullet")
                        }
                        
                        Button {
                            showingManagePayeesSheet = true
                        } label: {
                            Label("Payees", systemImage: "person")
                        }
                        
                        Button {
                            showOnboardSheet = true
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    } label: {
                        Text("Menu")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        newItemCategory = nil
                        showingCreateSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Item")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingManagePayeesSheet) {
                ManagePayeesView()
                    .onDisappear {
                        loadSectionTitles()
                    }
            }
            .sheet(isPresented: $showingManageCategoriesSheet) {
                ManageCategoriesView()
                    .onDisappear {
                        loadSectionTitles()
                    }
            }
            .sheet(item: $newItemCategory) { cat in
                CreateItemView(editingCategory: cat)
                    .onDisappear {
                        loadSectionTitles()
                    }
            }
            .sheet(isPresented: $showingEditSheet) {
                CreateItemView(editingItem: editingItem)
                    .onDisappear {
                        loadSectionTitles()
                        editingItem = nil
                    }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateItemView()
                    .onDisappear {
                        loadSectionTitles()
                    }
            }
            .sheet(isPresented: $showOnboardSheet) {
                OnboardingView()
            }
        }
    }
    
    /// Move in list and update model with correct Item.number
    private func move(from source: IndexSet, to destination: Int) {
        if let movedCategory = movedCategory {
            var items = movedCategory.templateItemsArray
            items.move(fromOffsets: source, toOffset: destination)
            Item.rearrangeItems(items: items, context: context)
            loadSectionTitles()
        }
    }
    
    /// hack to get section titles to update -_-
    private func loadSectionTitles() {
        let predicate = items.nsPredicate
        items.nsPredicate = NSPredicate(format: "name contains ''")
        items.nsPredicate = predicate
    }
}
