//
//  ManageCategoriesView.swift
//  Budget
//
//  Created by Cory Iley on 4/28/22.
//

import SwiftUI

struct ManageCategoriesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: [SortDescriptor(\.number)]) private var categories: FetchedResults<Category>
    
    @State private var sortedCategories: [Category] = []
    @State var editing: Category? = nil
    @State var editingCategoryName = ""
    
    @State private var deletion: Category? = nil
    @State private var showDeleteWarning = false
        
    @State private var showingNewCategorySection = false
    @State private var newCategoryName = ""
    @State private var showErrorAlert = false
    
    enum Field {
        case newCatName, editingCatName
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationView {
            List {
                if showingNewCategorySection {
                    Section {
                        HStack {
                            TextField("New Category Name", text: $newCategoryName)
                                .focused($focusedField, equals: .newCatName)
                            Button("Create") {
                                createNewCategory()
                            }
                        }
                    }
                }
                
                ForEach(sortedCategories) { category in
                    HStack {
                        if let editing = editing, category == editing {
                            TextField("Edit Name", text: $editingCategoryName)
                                .focused($focusedField, equals: .editingCatName)
                            Spacer()
                            Button("Save") {
                                withAnimation {
                                    editCategoryName()
                                }
                            }
                            .foregroundColor(.accentColor)
                        } else {
                            Text(category.name ?? "Error")
                            Group {
                                Spacer()
                                if category.name != "None" {
                                    Button {
                                        editingCategoryName = ""
                                        editing = category
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            focusedField = .editingCatName
                                        }
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    Button {
                                        showDeletionPrompt(category)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.accentColor)
                        }
                    }
                    .onDrag {
                        return NSItemProvider()
                    }
                    .foregroundColor(.primary)
                }
                .onMove(perform: move)
            }
            .navigationTitle("Manage Categories")
            .onAppear {
                sortedCategories = sortCategories()
            }
            .alert("Invalid name or already exists", isPresented: $showErrorAlert) { }
            .alert("Delete Category", isPresented: $showDeleteWarning, presenting: deletion) { category in
                Button("Delete", role: .destructive) {
                    delete(category)
                }
                Button("Cancel", role: .cancel) {}
            } message: { category in
                Text("Are you sure you want to delete \(category.name!)?")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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
    }
    
    /// Delete category and remove from list
    private func delete(_ category: Category) {
        if let index = sortedCategories.firstIndex(of: category) {
            sortedCategories.remove(at: index)
            category.delete(context: context)
        }
    }
    
    /// Prompt user to delete category
    private func showDeletionPrompt(_ category: Category) {
        deletion = category
        showDeleteWarning = true
    }
    
    /// Move in list and update model with correct Category.number
    private func move(from source: IndexSet, to destination: Int) {
        sortedCategories.move(fromOffsets: source, toOffset: destination)
        Category.rearrangeCategories(categories: sortedCategories, context: context)
    }
    
    /// Sort categories so that None is at top
    private func sortCategories() -> [Category] {
        var array = Array(categories)
        if let noneCatIndex = array.firstIndex(of: Category.getNoneCategory(context: context)) {
            array.move(fromOffsets: [noneCatIndex], toOffset: 0)
        }
        
        return array
    }
    
    /// Edit category name
    private func editCategoryName() {
        if let editing = editing, editing.edit(name: editingCategoryName, in: context) {
            self.editing = nil
            editingCategoryName = ""
            return
        }
        
        self.editing = nil
        editingCategoryName = ""
        showErrorAlert.toggle()
    }
    
    /// Create new category given name
    private func createNewCategory() {
        if Category.isValid(name: newCategoryName, context: context) {
            withAnimation {
                sortedCategories.append(Category.findOrCreate(name: newCategoryName, in: context))
                newCategoryName = ""
            }
            DispatchQueue.main.async {
                withAnimation {
                    showingNewCategorySection = false
                }
            }
            return
        }
        
        showErrorAlert.toggle()
    }
}
