//
//  StatisticsView.swift
//  Budget
//
//  Created by Cory Iley on 3/24/22.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var navController: NavController
    
    enum ChartType {
        case pie
        case bar
    }
    
    @State var month: Month
    @State var chartType: ChartType = .pie
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    PeriodSelectionView()
                }
                
                Section {
                    if chartType == .pie {
                        PieChartView(month: $month)
                    }
                }
            }
            .navigationTitle("Statistics")
        }
        
    }
}
