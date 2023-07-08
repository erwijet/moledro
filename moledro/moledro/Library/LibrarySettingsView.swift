//
//  LibrarySettingsView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/25/23.
//

import SwiftUI
import FirebaseFirestore

struct LibrarySettingsView: View {
    let library: Library
    let libraryDidDelete: () -> Void
    let libraryShouldDismiss: () -> Void
    let settingsShouldCommit: (LibrarySettings) -> Void
    
    @State private var draft: LibrarySettings
    @State private var isShowingDeleteAlert: Bool
    @State private var isDeleted: Bool = false
 
    init(library: Library, libraryDidDelete: @escaping () -> Void, libraryShouldDismiss: @escaping () -> Void, settingsShouldCommit: @escaping (LibrarySettings) -> Void) {
        self.library = library
        self.libraryDidDelete = libraryDidDelete
        self.libraryShouldDismiss = libraryShouldDismiss
        self.settingsShouldCommit = settingsShouldCommit
        
        _draft = State.init(wrappedValue: LibrarySettings(showDDC: library.settings.showDDC, showFastSubjects: library.settings.showFastSubjects, showTags: library.settings.showTags, showPreview: library.settings.showPreview, sortBy: library.settings.sortBy))
        
        self._isShowingDeleteAlert = State.init(initialValue: false)
    }
    
    
    var body: some View {
        VStack {
            NavigationStack {
                Form {
                    Section {
                        LabeledContent("Name", value: library.name)
                        LabeledContent("Owner", value: library.ownerUID)
                    }
                    
                    NavigationLink("Gallery Items") {
                        Form {
                            Section {
                                Toggle("Dewey Decimal Classifiers", isOn: $draft.showDDC)
                            } footer: {
                                Text("The Dewey decimal classifier (DDC) is often used to organize nonfiction books by topic. Turning this on will show the DDC for each book in the library gallery view.")
                            }
                            
                            Section {
                                Toggle("FAST Subject Headings", isOn: $draft.showFastSubjects)
                            } footer: {
                                Text("FAST (Faceted Application of Subject Terminology) is a system used to classify books by subject. Turning this on will show the FAST Subject Headings for each book in the library gallery view.")
                            }
                            
                            Section {
                                Toggle("Tags", isOn: $draft.showTags)
                                Toggle("Cover Preview", isOn: $draft.showPreview)
                            } footer: {
                                Text("Inlined options for books the gallery view")
                            }
                        }
                        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                        .navigationTitle("Gallery Items")
                    }
                    
                    Section {
                        Button("Delete Library") {
                            isShowingDeleteAlert = true
                        }.tint(.red)
                    }
                }
                .alert(isPresented: $isShowingDeleteAlert) {
                    Alert(
                        title: Text("Are you sure?"),
                        message: Text("Are you sure you want to delete '\(library.name)'"),
                        primaryButton: .destructive(Text("Delete")) {
                            handleDelete()
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                .navigationTitle("Library Settings")
                .toolbar {
                    Button("Done") {
                        libraryShouldDismiss()
                    }
                }
            }
        }.onDisappear {
            if !isDeleted {
                settingsShouldCommit(draft)
            }
        }
    }
    
    func handleDelete() {
        let db = Firestore.firestore()
        
        db.document("libraries/\(library.id)").delete { error in
            if let error = error {
                print(error.localizedDescription)
            }
            
            isDeleted = true
            
            libraryDidDelete()
        }
    }
}


