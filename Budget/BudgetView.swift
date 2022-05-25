//
//  HomeView.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI
import CoreData

struct BudgetView: View {
    @Environment(\.managedObjectContext) var context
    @SectionedFetchRequest(sectionIdentifier: \.categoryName, sortDescriptors: [SortDescriptor(\.category!.number), SortDescriptor(\.templateItem!.number)], animation: .none) private var items: SectionedFetchResults<String, Item>
    @EnvironmentObject private var navController: NavController
    
    init(month: Month) {
        _month = State(initialValue: month)
        _items = SectionedFetchRequest<String, Item>(sectionIdentifier: \.categoryName, sortDescriptors: [SortDescriptor(\.category!.number), SortDescriptor(\.templateItem!.number)], predicate: NSPredicate(format: "month == %@", month))
    }
    
    @State var month: Month
    @State private var itemForTransaction: Item? = nil
    @State private var showingCreateTransactionView = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    PeriodSelectionView()
                }
                
                Section {
//                    SpendingAndBalanceView(month: selectedPeriod)
                    let budgeted = month.totalBudgeted.currencyFormatted
                    let spending = month.totalSpent.currencyFormatted
                    let balance = month.totalBalance.currencyFormatted
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Budgeted: \(budgeted)")
                            Text("Balance: \(balance)")
                            Text("Transactions: \(month.allTransactions.count)")
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Spending")
                            Text(spending)
                                .font(.largeTitle)
                                .foregroundColor(month.totalBalance >= 0 ? .green : .red)
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)
                        }
                    }
                }
                
                ForEach(items) { category in
                    let title = category.id == "None" ? "Uncategorized" : category.id
                    Section(header: Text(title)) {
                        ForEach(category) { item in
                            NavigationLink {
                                BudgetItemView(item: item)
                            } label: {
                                HStack {
                                    Text(item.name ?? "Error")
                                    Spacer()
                                    Text(item.totalRemaining.currencyFormatted)
                                        .foregroundColor(.secondary)
                                }
                                .contextMenu {
                                    Button("New Transaction") { itemForTransaction = item }
                                }
                            }
                        }
                    }
                    .headerProminence(.increased)
                }
                
            }
            .navigationTitle("1Budget")
            .onChange(of: navController.selectedMonth) { month in
                if let month = month {
                    loadMonth(month: month)
                }
                
            }
            .onAppear {
                loadSectionTitles()
                if let month = navController.selectedMonth {
                    self.month = month
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTransactionView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                    }
                }
            }
            .sheet(isPresented: $showingCreateTransactionView) {
                CreateTransactionView()
            }
            .sheet(item: $itemForTransaction) { item in
                CreateTransactionView(item: item)
            }
        }
    }
    
    func loadMonth(month: Month) {
        self.month = month
        items.nsPredicate = NSPredicate(format: "month == %@", month)
    }
    
    func loadSectionTitles() {
        // hack to get section titles to update -_-
        let predicate = items.nsPredicate
        items.nsPredicate = NSPredicate(format: "name contains ''")
        items.nsPredicate = predicate
    }
}
