//
//  ManagePayeesView.swift
//  Budget
//
//  Created by Cory Iley on 4/26/22.
//

import SwiftUI

struct ManagePayeesView: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) private var payees: FetchedResults<Payee>
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(payees) { payee in
                    NavigationLink {
                        PayeeView(payee: payee)
                    } label: {
                        Text(payee.name!)
                    }
                }
            }
            .navigationTitle("Manage Payees")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
