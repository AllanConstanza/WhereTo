//
//  CityCardView.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/12/25.
//
import SwiftUI
import UIKit

struct CityCardView: View {
    let city: City
    var distance: Double? = nil

    var body: some View {
        HStack {
            Group {
                if let data = city.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else if let url = city.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: Rectangle().fill(Color.gray.opacity(0.3))
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure: Rectangle().fill(Color.gray.opacity(0.3))
                        @unknown default: Rectangle().fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.title3).fontWeight(.semibold)

                if let d = distance {
                    let miles = d / 1609.344
                    Text(String(format: "%.1f mi away", miles))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


