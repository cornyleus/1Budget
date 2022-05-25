//
//  PieChartView.swift
//  Budget
//
//  Created by Cory Iley on 3/25/22.
//

import SwiftUI

struct PieChartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navController: NavController
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) private var itemsFetchRequest: FetchedResults<Item>
    
    enum ViewType {
        case categories
        case items
        case payees
        case transactions
    }
    
    @Binding var month: Month
    @State var selectedCategory: Category? = nil
    @State var selectedItem: Item? = nil
    @State var selectedPayee: Payee? = nil
    
    @State var displaying: ViewType = .categories {
        didSet {
            withAnimation {
                loadSlices()
            }
        }
    }
    @State var showingAll: Bool = false {
        didSet {
            withAnimation {
                loadSlices()
            }
        }
    }
    var monthOrAll: Month? {
        showingAll == true ? nil : month
    }
    
    @State var showingPercentage = false
    
    var items: [Item] {
        if itemsFetchRequest.count == 0 { return [] }
        if showingAll {
            return itemsFetchRequest.filter { $0.month == nil }.sorted { $0.totalSpent > $1.totalSpent }
        } else {
            return itemsFetchRequest.filter { $0.month == month }.sorted { $0.totalSpent > $1.totalSpent }
        }
    }
    
    var totalItemsAmount: Decimal {
        items.map { $0.totalSpent }.reduce(0, +)
    }
    
    @State var slices: [Slice] = [] {
        didSet {
            if slices.count == 0 {
                resetView()
            }
        }
    }
    
    var body: some View {
        Group {
            if slices.count > 0 {
                if totalItemsAmount > 0 {
                    Section {
                        GeometryReader { geo in
                            ZStack {
                                ForEach(0 ..< slices.count, id: \.self) { i in
                                    let center = CGPoint(x: geo.frame(in: .global).width / 2, y: geo.frame(in: .global).height / 2)
                                    DrawShape(data: slices, center: center, index: i)
                                        .onTapGesture {
                                            if displaying == .categories {
                                                selectedCategory = Category.findOrCreate(name: slices[i].title, in: context)
                                                displaying = .items
                                            } else if displaying == .items {
                                                if let item = Item.getItem(named: slices[i].title, in: monthOrAll, context: context) {
                                                    selectedItem = item
                                                    displaying = .payees
                                                }
                                            } else if displaying == .payees {
                                                selectedPayee = Payee.findOrCreate(name: slices[i].title, in: context)
                                                displaying = .transactions
                                            } else if displaying == .transactions {
                                                displaying = .categories
                                            }
                                        }
                                }
                            }
                        }
                        .frame(height: 360)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    HStack {
                        if displaying == .categories {
                            Text("Categories")
                        }
                        
                        if displaying == .items {
                            if let selectedCategory = selectedCategory, let catName = selectedCategory.name {
                                Button(catName) { displaying = .categories }
                                    .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        
                        if displaying == .payees {
                            if let selectedItem = selectedItem, let itemName = selectedItem.name {
                                Button(itemName) { displaying = .items }
                                    .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        
                        if displaying == .transactions {
                            if let selectedPayee = selectedPayee, let payeeName = selectedPayee.name {
                                Button(payeeName) { displaying = .payees }
                                    .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        
                        Text(">")
                        Button(showingAll ? "All Transactions" : month.description) { showingAll.toggle() }
                            .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    ForEach(slices) { slice in
                            HStack(alignment: .top) {
                                Button {
                                    if displaying == .categories {
                                        let category = Category.findOrCreate(name: slice.title, in: context)
                                        if category.totalSpent(in: monthOrAll) > 0 {
                                            selectedCategory = category
                                            displaying = .items
                                        }
                                    } else if displaying == .items {
                                        if let item = Item.getItem(named: slice.title, in: monthOrAll, context: context),
                                           item.totalSpent > 0 {
                                            selectedItem = item
                                            displaying = .payees
                                        }
                                    } else if displaying == .payees {
                                        if let payee = Payee.findOrCreate(name: slice.title, in: context),
                                           payee.totalSpent(in: monthOrAll, item: selectedItem) > 0 {
                                            selectedPayee = payee
                                            displaying = .transactions
                                        }
                                    } else if displaying == .transactions {
                                        resetView()
                                    }
                                } label: {
                                    Text(slice.title)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Spacer()
                                GeometryReader { geo2 in
                                    HStack {
                                        Spacer(minLength: 0)
                                        Rectangle()
                                            .fill(slice.color)
                                            .frame(width: getWidth(width: geo2.frame(in: .global).width, value: slice.percent), height: 15)
                                    }
                                    
                                }
                                
                                Group {
                                    if showingPercentage {
                                        Text(String(format: "%.0f%%", slice.percent))
                                    } else {
                                        Text(slice.value.currencyFormatted)
                                    }
                                }
                                .onTapGesture {
                                    withAnimation {
                                        showingPercentage.toggle()
                                    }
                                }
                                .padding(.leading, 10)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            }

                    }
                }
                .listRowSeparator(.hidden)
                
            } else {
                Text("Create budget items to view statistics.")
            }
        }
        .onChange(of: navController.selectedMonth ?? self.month) { month in
            self.month = month
            withAnimation {
                loadSlices()
            }
        }
        
        .onAppear {
            if let month = navController.selectedMonth {
                self.month = month
            }
            
            loadSlices()
        }
    }
    
    /// Reset view to display categories -- for when no slices are present to form graph
    func resetView() {
        displaying = .categories
        selectedCategory = nil
        selectedItem = nil
        selectedPayee = nil
    }
    
    /// Load slices to create graph
    func loadSlices() {
        if !items.isEmpty {
            var slices: [Slice] = []
            
            let colors = [
                Color.blue,
                Color.cyan,
                Color.mint,
                Color.green,
                Color.yellow,
                Color.orange,
                Color.red,
                Color.brown,
                Color.pink,
                Color.purple,
                Color.indigo
            ]
            
            /// Initially showing categories
            if displaying == .categories {
                let categories = Array(Set(items.map { $0.category! }))
                    .sorted { $0.totalSpent(in: monthOrAll) > $1.totalSpent(in: monthOrAll) }
                
                categories.indices.forEach { index in
                    var percentage: Decimal = 0
                    if self.totalItemsAmount > 0 {
                        percentage = (categories[index].totalSpent(in: monthOrAll) / totalItemsAmount) * 100
                    }
                    
                    let slice = Slice(
                        id: index,
                        percent: CGFloat(truncating: percentage as NSNumber),
                        color: colors[index % colors.count],
                        title: categories[index].name!,
                        value: categories[index].totalSpent(in: monthOrAll)
                    )
                    
                    slices.append(slice)
                }
            }
                
            
            /// Showing Items within selected category
            if displaying == .items {
                if let selectedCategory = selectedCategory {
                    let items = selectedCategory.itemsIn(month: monthOrAll)
                            .sorted { $0.totalSpent > $1.totalSpent }
                    
                    items.indices.forEach { index in
                        var percentage: Decimal = 0
                        let categoryTotal = selectedCategory.totalSpent(in: monthOrAll)
                        if categoryTotal > 0 {
                            percentage = (items[index].totalSpent / categoryTotal) * 100
                        }
                        
                        let slice = Slice(
                            id: index,
                            percent: CGFloat(truncating: percentage as NSNumber),
                            color: colors[index % colors.count],
                            title: items[index].name!,
                            value: items[index].totalSpent
                        )
                        
                        slices.append(slice)
                    }
                }
            }
            
            if displaying == .payees {
                if let selectedItem = selectedItem {
                    let payees = Array(Set(selectedItem.getTransactions().map { $0.payee! }))
                        .sorted { $0.totalSpent(in: monthOrAll, item: selectedItem) > $1.totalSpent(in: monthOrAll, item: selectedItem) }
                    
                    payees.indices.forEach { index in
                        let payeeTotal = payees[index].totalSpent(in: monthOrAll, item: selectedItem)
                        let itemTotal = selectedItem.totalSpent
                        
                        var percentage: Decimal = 0
                        if itemTotal > 0 {
                            percentage = (payeeTotal / itemTotal) * 100
                        }

                        let slice = Slice(
                            id: index,
                            percent: CGFloat(truncating: percentage as NSNumber),
                            color: colors.randomElement()!,
                            title: payees[index].name!,
                            value: payeeTotal
                        )

                        slices.append(slice)
                    }
                }
            }
            
            if displaying == .transactions {
                if let selectedPayee = selectedPayee {
                    let transactions = selectedPayee.transactionsFrom(month: monthOrAll, item: selectedItem)
                        .sorted { ($0.amount! as Decimal) > ($1.amount! as Decimal) }
                                    
                    transactions.indices.forEach { index in
                        let amount = transactions[index].amount! as Decimal
                        let payeeTotal = selectedPayee.totalSpent(in: monthOrAll, item: selectedItem)

                        var percentage: Decimal = 0
                        if payeeTotal > 0 {
                            percentage = (amount / payeeTotal) * 100
                        }

                        let slice = Slice(
                            id: index,
                            percent: CGFloat(truncating: percentage as NSNumber),
                            color: colors.randomElement()!,
                            title: dateFormatter.string(from: transactions[index].date!),
                            value: amount
                        )

                        slices.append(slice)
                    }
                    
                }
            }
            
            self.slices = slices

        }
    }
    
    func getWidth(width: CGFloat, value: CGFloat) -> CGFloat {
        let temp = value / 100
        return temp * width
    }
}

struct Slice: Identifiable {
    var id: Int
    var percent: CGFloat
    var color: Color
    var title: String
    var value: Decimal
}

struct DrawShape: View {
    
    var data: [Slice] = []
    var center: CGPoint
    var index: Int
    
    var body: some View {
        
        if !data.isEmpty {
            Path { path in
                path.move(to: self.center)
                path.addArc(center: center, radius: 180, startAngle: .init(degrees: from()), endAngle: .init(degrees: to()), clockwise: false)
            }
            .fill(data[index].color)
        }
    }
    
    func from() -> Double {
        if index == 0 || data.isEmpty {
            return 0
        }
        
        var temp: Double = 0
        
        for i in 0...index-1 {
            temp += Double(data[i].percent / 100) * 360
        }
        
        return temp
    }
    
    func to() -> Double {
        if data.isEmpty {
            return 0
        }
        
        var temp: Double = 0
        
        for i in 0...index {
            temp += Double(data[i].percent / 100) * 360
        }
        
        return temp
    }
    
}
