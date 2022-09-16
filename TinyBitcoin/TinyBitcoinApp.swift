//
//  TinyBitcoinApp.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 6/12/22.
//

import SwiftUI
import Starscream
import AppKit

@main
struct TinyBitcoinApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var priceData = PriceData.shared
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }
    
    var price: Double {
        return chart.last?.close ?? priceData.lastPrice
    }
    
    var menuLabel: String {
        let a = priceData.dailyChange < 0 ? "⬇" : "⬆"
        let change = priceData.dailyChange.formatted(.percent.precision(.fractionLength(2)))
        return "\(price.formatted(.currency(code: "usd").precision(.fractionLength(0)))) \(a) \(change)"
    }
    
    var body: some Scene {
        MenuBarExtra(priceData.lastPrice > .zero ? menuLabel : "₿") {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: NSColor.windowBackgroundColor))
                .environmentObject(priceData)
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 500, height: 275)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidChangeOcclusionState(_ notification: Notification) {
        if !PriceData.shared.tickerSocketConnected {
            Task {
                await PriceData.shared.connectTickerSocket()
            }
        } else {
            Task {
                await PriceData.shared.disconnectTickerSocket()
            }
        }
        if !PriceData.shared.candleSocketConnected {
            Task {
                await PriceData.shared.connectCandleSocket()
            }
        } else {
            Task {
                await PriceData.shared.disconnectCandleSocket()
            }
        }
    }
}
