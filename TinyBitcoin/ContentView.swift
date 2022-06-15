//
//  ContentView.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 6/12/22.
//

import SwiftUI
import Charts

struct ContentView: View {
    
    @EnvironmentObject var priceData: PriceData
    @State private var retrying = false
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }

    var yAxis: [Double] {
        return chart.map { $0.close }.sorted(by: { $0 < $1 })
    }
    
    var xAxis: [Date] {
        return chart.map { $0.time }.sorted(by: { $0 < $1 })
    }
    
    var body: some View {
        LazyVStack(spacing: 16) {
            
            HStack {
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(priceData.lastPrice.formatted(.currency(code: "usd").precision(.fractionLength(0))))")
                        .font(.system(size: 22, weight: .bold))
                    Text(getChangeText())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(priceData.dailyChange < 0 ? .red : .green)
                }
                
                Spacer()
                
                HStack {
                    Text("Tiny Bitcoin")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.secondary)
                    
                    Image("btc")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25)
                }
            }
            
            Picker("", selection: $priceData.chartTime) {
                ForEach(PriceData.ChartTime.allCases, id: \.self) { time in
                    Text(time.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: priceData.chartTime) { newValue in
                Task {
                    await PriceData.shared.connectCandleSocket()
                }
            }
            .padding(.horizontal, 16)
            .offset(x: -3, y: 0)
            
            Chart {
                ForEach(chart, id: \.close) {
                    
                    RectangleMark(x: .value("Date", $0.time),
                                  yStart: .value("Price", $0.open),
                                  yEnd: .value("Price", $0.close))
                        .foregroundStyle($0.close < $0.open ? .red : .green)
                    
                    BarMark(x: .value("Date", $0.time),
                            yStart: .value("Price", $0.low),
                            yEnd: .value("Price", $0.high),
                            width: .fixed(1))
                        .foregroundStyle($0.close < $0.open ? .red : .green)

                }
                
                if let l = chart.last {
                    RuleMark(y: .value("Price", l.close))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(l.close < l.open ? .red : .green)
                }
                
            }
            .chartXScale(domain: xAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartYScale(domain: yAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .frame(height: 150)
            .padding(.vertical, 8)  // TODO: might need tweek?

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
                }

                Spacer()
                Button("Quit", action: {
                    NSApp.terminate(self)
                })
                .buttonStyle(.bordered)
            }

        }
        .padding()
    }
    
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PriceData.shared)
            .task {
                await PriceData.shared.connectTickerSocket()
                await PriceData.shared.connectCandleSocket()
            }
    }
}
