////
////  ImageLoader.swift
////  moledro
////
////  Created by Tyler Holewinski on 6/18/23.
////
//
//import Foundation
//import SwiftUI
//
//class ImageLoader: ObservableObject {
//    @Published var image: UIImage?
//    
//    init(imageURL: URL) {
//        downloadImage(from: imageURL)
//    }
//    
//    private func downloadImage(from url: URL) {
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            guard let data = data, error == nil else { return }
//            
//            DispatchQueue.main.async {
//                self.image = UIImage(data: data)
//            }
//        }.resume()
//    }
//}
