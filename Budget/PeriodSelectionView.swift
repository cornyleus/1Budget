//
//  PeriodSelectionView.swift
//  Budget
//
//  Created by Cory Iley on 4/3/22.
//

import SwiftUI
import CoreData

struct PeriodSelectionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var navController: NavController
    @Namespace var animation
    @State private var showingCreatePreviousButton = false
    @State private var showingCreateNextButton = false
    
    class Period: Identifiable, Equatable {
        static func == (lhs: PeriodSelectionView.Period, rhs: PeriodSelectionView.Period) -> Bool {
            lhs.date.getStart(of: .month) == rhs.date.getStart(of: .month)
        }
        
        let id = UUID()
        let date: Date
        
        init() {
            date = Date().getStart(of: .month) ?? Date()
        }
        
        init(date: Date) {
            self.date = date.getStart(of: .month) ?? date
        }
                
        static func initialMonths() -> [Period] {
            let year = Calendar.current.component(.year, from: Date())
            return createMonths(for: year)
        }
        
        static func createMonths(for year: Int) -> [Period] {
            var months: [Period] = []
            
            (1...12).forEach { index in
                var components = DateComponents()
                components.year = year
                components.month = index
                if let date = Calendar.current.date(from: components) {
                    months.append(Period(date: date))
                }
            }
            
            return months
        }
    }
    
    @State var selectedPeriod: Period
    @State var periods: [Period]
    
    init() {
        let months = Period.initialMonths()
        let currentMonth = months.first(where: { month in
            month.date.getStart(of: .month) == Date().getStart(of: .month)
        }) ?? Period()
        
        _periods = State(initialValue: months)
        _selectedPeriod = State(initialValue: currentMonth)
    }
    
    @State private var selectedPeriodIndex: Int = -1 {
        didSet {
            if selectedPeriodIndex == 0 {
                // first element
                showingCreatePreviousButton = true
            } else if selectedPeriodIndex == periods.count - 1 {
                // last element
                showingCreateNextButton = true
            } else {
                showingCreatePreviousButton = false
                showingCreateNextButton = false
            }
        }
    }
        
    var body: some View {
        let unselectedPeriodTextColor: Color = colorScheme == .dark ? .white : .black
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if showingCreatePreviousButton {
                        Button {
                            createPrevious()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                    ForEach(0..<periods.count, id: \.self) { index in
                        VStack {
                            Text("\(periods[index].date.stringWithFormat("MMM"))")
                            Text("\(periods[index].date.stringWithFormat("yy"))")
                        }
                        
                        .frame(width: 55, height: 55)
                        .foregroundStyle(index == selectedPeriodIndex ? .primary : .secondary)
                        .foregroundColor(index == selectedPeriodIndex ? .white : unselectedPeriodTextColor)
                        .background(
                            ZStack {
                                if index == selectedPeriodIndex {
                                    Circle()
                                        .fill(colorScheme == .dark ? Color(white: 0.2) : .black)
                                        .matchedGeometryEffect(id: "CURRENTMONTH", in: animation)
                                }
                            }
                            
                        )
                        .contentShape(Circle())
                        .onTapGesture {
                            self.set(period: periods[index])
                            withAnimation {
                                proxy.scrollTo(index, anchor: .center)
                                selectedPeriodIndex = index
                            }
                        }
                    }
                    
                    if showingCreateNextButton {
                        Button {
                            createNext()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .onChange(of: selectedPeriodIndex) { index in
                withAnimation {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            
        }
        .onChange(of: navController.selectedMonth) { _ in
            createRequiredPeriods()
        }
        .onAppear {
            createRequiredPeriods()
        }
    }
    
    func createRequiredPeriods() {
//        if let begin = navController.getEarliestMonthDate() {
//            if periods.first == nil { return }
//            var firstPeriodDate = periods.first!.date
//            
//            while firstPeriodDate > begin {
//                createPrevious(set: false)
//                firstPeriodDate = periods.first!.date
//            }
//        }
//        
//        if let end = navController.getLatestMonthDate() {
//            if periods.last == nil { return }
//            var latestPeriodDate = periods.last!.date
//            
//            while latestPeriodDate < end {
//                createNext(set: false)
//                latestPeriodDate = periods.last!.date
//            }
//        }
        
        if let month = navController.selectedMonth {
            if let period = getPeriod(from: month) {
                selectedPeriod = period
                selectedPeriodIndex = periods.firstIndex(of: selectedPeriod) ?? 0
            } else {
                if month.date < Date() {
                    if periods.first == nil { return }
                    var firstPeriodDate = periods.first!.date
                    
                    while firstPeriodDate > month.date {
                        createPrevious(set: false)
                        firstPeriodDate = periods.first!.date
                    }
                }
                
                if month.date > Date() {
                    if periods.last == nil { return }
                    var latestPeriodDate = periods.last!.date
                    
                    while latestPeriodDate < month.date {
                        createNext(set: false)
                        latestPeriodDate = periods.last!.date
                    }
                }
            }
        }
    }
    
    /// Get PeriodSelectionView.Period from passed Budget.Month value
    func getPeriod(from budgetMonth: Budget.Month) -> Period? {
        if let month = periods.first(where: { month in
            month.date.getStart(of: .month) == budgetMonth.date
        }) {
            return month
        }
        return nil
        return Period(date: budgetMonth.date)
    }
    
    /// Set PeriodSelectionView.Period, keep in sync with navController.selectedPeriod
    func set(period: Period) {
        self.selectedPeriod = period
        
        let monthInt = Calendar.current.component(.month, from: period.date)
        let yearInt = Calendar.current.component(.year, from: period.date)
        
        if let budgetPeriod = navController.getMonth(month: monthInt, year: yearInt) {
            navController.set(month: budgetPeriod)
        } else {
            navController.createMonth(month: monthInt, year: yearInt)
        }
        
    }
    
    /// Create previous year's worth of PeriodSelectionView.Periods
    func createPrevious(set: Bool = true) {
        if let firstPeriod = periods.first {
            if let previousYear = Calendar.current.date(byAdding: .year, value: -1, to: firstPeriod.date) {
                let yearInt = Calendar.current.component(.year, from: previousYear)
                let newMonths = Period.createMonths(for: yearInt)
                periods.insert(contentsOf: newMonths, at: 0)
                if set {
                    selectedPeriodIndex = 11
                    self.set(period: periods[11])
                }
                
            }
        }
    }
    
    /// Create next year's worth of PeriodSelectionView.Periods
    func createNext(set: Bool = true) {
        if let lastPeriod = periods.last {
            if let nextYear = Calendar.current.date(byAdding: .year, value: 1, to: lastPeriod.date) {
                let yearInt = Calendar.current.component(.year, from: nextYear)
                let newMonths = Period.createMonths(for: yearInt)
                periods.append(contentsOf: newMonths)
                if set {
                    selectedPeriodIndex += 1
                    self.set(period: periods[selectedPeriodIndex])
                }
                
            }
        }
    }
}
