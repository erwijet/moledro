//
//  FirebaseStorageImageLoader.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/11/23.
//

import Foundation
import FirebaseStorage
import SwiftUI

struct FirebaseStoreImageLoader<Content: View, Fallback: View>: View {
    @StateObject private var imageLoader: ImageLoader
    
    @ViewBuilder private var content: (UIImage) -> Content
    @ViewBuilder private var fallback: () -> Fallback
    
    init(reference: StorageReference, @ViewBuilder fallback: @escaping () -> Fallback, @ViewBuilder content: @escaping (UIImage) -> Content) {
        self.content = content
        self.fallback = fallback
        
        _imageLoader = StateObject(wrappedValue: ImageLoader(reference: reference))
    }
    
    var body: some View {
        if let image = imageLoader.image {
            content(image)
        } else {
            fallback()
        }
    }
}

class ImageLoader: ObservableObject {
    private let reference: StorageReference
    
    @Published var image: UIImage? = nil
    
    init(reference: StorageReference) {
        self.reference = reference
        loadData()
    }
    
    private func loadData() {
        reference.getData(maxSize: 500000000) { [weak self] data, error in
            guard let data = data, let image = UIImage(data: data) else {
                print(error?.localizedDescription ?? "No data was returned")
                return
            }
            
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
}
