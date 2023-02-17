//
//  ViewModifiers.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 10/26/22.
//

import Foundation
import SwiftUI

struct BorderStyle: ViewModifier {
    
    let title: String
    let systemImageName: String
    let imageColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
            )
            .overlay(
                VStack(alignment: .leading) {
                    Label(title: {
                        Text(title)
                            .font(.system(.body,
                                          design: .monospaced,
                                          weight: .regular))
                            .lineLimit(1)
                            .offset(x: -2, y: 0)
                    }, icon: {
                        Image(systemName: systemImageName)
                            .foregroundColor(imageColor)
                            .fontWeight(.bold)
                    })
                    .minimumScaleFactor(0.2)
                    .padding(.horizontal, 4)
                    .foregroundColor(Color.text)
                    .background(
                        Rectangle()
                            .foregroundColor(Color.background)
                    )
                }
                .foregroundColor(Color.text)

                .offset(x: 6, y: -10)
                , alignment: .topLeading
            )
    }
}
