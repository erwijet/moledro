//
//  ChipView.swift
//  moledro
//
//  Created by Tyler Holewinski on 7/7/23.
//

import SwiftUI

struct ChipView: View {
    var title: String
    var backgroundColor: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(4)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}
