//
//  ScannerView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/19/23.
//

import SwiftUI
import BarcodeScanner

struct IsbnScanAndQueryView: UIViewControllerRepresentable {
    typealias UIViewControllerType = BarcodeScannerViewController
    
    let didScan: (CoelhoResponse?) -> Void
    let willDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let viewController = BarcodeScannerViewController()
        
        viewController.codeDelegate = context.coordinator
        viewController.errorDelegate = context.coordinator
        viewController.dismissalDelegate = context.coordinator
        
        viewController.messageViewController.messages.processingText = "Seaching ISBN..."
        viewController.messageViewController.messages.notFoundText = "No Results"
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        //
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(willDismiss: self.willDismiss, didScan: self.didScan)
    }
    
    class Coordinator: NSObject, BarcodeScannerCodeDelegate, BarcodeScannerErrorDelegate, BarcodeScannerDismissalDelegate {
        let willDismiss: () -> Void
        let didScan: (CoelhoResponse?) -> Void
        
        init(willDismiss: @escaping () -> Void, didScan: @escaping (CoelhoResponse?) -> Void) {
            self.willDismiss = willDismiss
            self.didScan = didScan
        }
        
        func scanner(_ controller: BarcodeScanner.BarcodeScannerViewController, didCaptureCode code: String, type: String) {
            guard let url = URL(string: "https://coelho.holewinski.dev/isbn/search?q=\(code)") else { return }
            
            let task = URLSession.shared.dataTask(with: url) { data, _, err in
                if let err = err {
                    controller.resetWithError(message: err.localizedDescription)
                    self.willDismiss()
                    return
                }
                
                guard let data = data else {
                    controller.resetWithError(message: "No data")
                    self.willDismiss()
                    return
                }
                
                let decoder = JSONDecoder()
                guard let coelhoResponse = try? decoder.decode(CoelhoResponse.self, from: data) else {
                    controller.resetWithError(message: "Couldn't find a match\n[ISBN \(code)]")
                    self.willDismiss()
                    return
                }
                
                DispatchQueue.main.async {
                    controller.reset(animated: true)
                    
                    self.didScan(coelhoResponse)
                    self.willDismiss()
                }
            }
            
            task.resume()
        }
        
        func scanner(_ controller: BarcodeScanner.BarcodeScannerViewController, didReceiveError error: Error) {
            controller.resetWithError(message: error.localizedDescription)
            self.willDismiss()
        }
        
        func scannerDidDismiss(_ controller: BarcodeScanner.BarcodeScannerViewController) {
            controller.reset(animated: true)
            self.willDismiss()
        }
    }
}

struct ScannerView: View {
    @State private var isPresentingScanner = true
    @State private var isPresentingSheet = false
    @State private var bookInfo: BookInfo?
    
    var body: some View {
        if let book = bookInfo {
//            BookInfoDetailView(bookInfo: book)
        }
        
        Button("Open Scanner") {
            isPresentingSheet = true
        }.sheet(isPresented: $isPresentingSheet, onDismiss: { bookInfo = nil }) {
            IsbnScanAndQueryView { coelhoResponse in
                bookInfo = coelhoResponse?.result
            } willDismiss: {
                isPresentingSheet = false
            }
        }
    }
}
