//
//  ContentView.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 10/26/22.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var priceData: PriceData
    @State private var retrying = false
    
    func getChangeText() -> String {
        let a = priceData.dailyChange < 0 ? "⬇" : "⬆"
        let change = priceData.dailyChange.formatted(.percent.precision(.fractionLength(2)))
        return "\(a) \(change)"
    }
    
    func getConnectText() -> String {
        if retrying {
            return "Trying to reconnect..."
        } else if PriceData.shared.tickerSocketConnected {
            return "Connected to Bitfinex"
        } else {
            return "Not connected"
        }
    }
    
    var body: some View {
        ZStack {
            Color.background
                .edgesIgnoringSafeArea(.all)
            
            LazyVStack(spacing: 16) {
                
                Text("Tiny Bitcoin")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color.text)
                
                MarketView()
                
                HStack {
                    HStack {
                        Button(action: {
                            Task {
                                retrying = true
                                await PriceData.shared.disconnectTickerSocket()
                                await PriceData.shared.disconnectCandleSocket()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                    Task {
                                        await PriceData.shared.connectTickerSocket()
                                        await PriceData.shared.connectCandleSocket()
                                        retrying = false
                                    }
                                })
                            }
                        }) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(priceData.tickerSocketConnected ? .green : .red)
                        }
                        .buttonStyle(.plain)
                        .disabled(retrying)
                        Text(getConnectText())
                            .font(.subheadline)
                            .foregroundColor(Color.text.opacity(0.8))
                    }

                    Spacer()
                    Button("Quit", action: {
                        NSApp.terminate(self)
                    })
                    .font(.system(.subheadline, design: .monospaced))
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(Color.text)
                    
                }
                
            }
            .padding()

        }
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 435, height: 315)
            .environmentObject(PriceData.shared)
    }
}
