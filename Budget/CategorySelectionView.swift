//
//  CategoriesView.swift
//  Budget
//
//  Created by Cory Iley on 3/15/22.
//

import SwiftUI

struct CategorySelectionView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @FetchRequest(sortDescriptors: [SortDescriptor(\.number)]) var categories: FetchedResults<Category>
    
    var sortedCategories: [Category] {
        var array = Array(categories)
        if let noneCatIndex = array.firstIndex(of: Category.getNoneCategory(context: context)) {
            array.move(fromOffsets: [noneCatIndex], toOffset: 0)
        }
        
        return array
    }
    
    @Binding var selectedCategory: Category?
        
    @State private var showingNewCategorySection = false
    @State private var newCategoryName = ""
    @State private var showErrorAlert = false
    
    enum Field {
        case newCatName
    }
    
    @FocusState private var focusedField: Field?

    var body: some View {
        List {
            if showingNewCategorySection {
                Section {
                    HStack {
                        TextField("New Category Name", text: $newCategoryName)
                            .focused($focusedField, equals: .newCatName)
                        Button("Create") {
                            createNewCategory(andDismiss: true)
                        }
                    }
                }
            }
            
            ForEach(sortedCategories) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack {
                            Text(category.name ?? "Error")
                            Group {
                                if category == selectedCategory {
                                    Image(systemName: "checkmark")
                                }
                                Spacer()
                            }
                            .foregroundColor(.accentColor)
                    }
                    .foregroundColor(.primary)
                    
                }
            }
        }
        .navigationTitle("Select Category")
        .alert("Invalid name or already exists", isPresented: $showErrorAlert) { }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !showingNewCategorySection {
                    Button("New") {
                        withAnimation {
                            showingNewCategorySection.toggle()
                            focusedField = .newCatName
                        }
                    }
                }
            }
        }
    }
    
    private func createNewCategory(andDismiss: Bool = false) {
        if Category.isValid(name: newCategoryName, context: context) {
            withAnimation {
                selectedCategory = Category.findOrCreate(name: newCategoryName, in: context)
                newCategoryName = ""
            }
            DispatchQueue.main.async {
                withAnimation {
                    showingNewCategorySection = false
                }
            }
            if andDismiss {
                dismiss()
            }
            return
        }

        showErrorAlert.toggle()
    }
}
