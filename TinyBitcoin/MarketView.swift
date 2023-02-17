//
//  MarketView.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 10/26/22.
//

import SwiftUI
import Charts

struct MarketView: View {
    
    @EnvironmentObject var priceData: PriceData
    @State private var retrying = false
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }
    
    var price: Double {
        return chart.last?.close ?? priceData.lastPrice
    }

    var yAxis: ClosedRange<Double> {
        var combined = chart.map{ $0.open }
        combined.append(contentsOf: chart.map{ $0.close })
        let sorted = combined.sorted(by: { $0 < $1 })
        let first = (sorted.first ?? 0.0)
        let last = (sorted.last ?? 0.0)
        return first...last
    }
    
    var xAxis: ClosedRange<Date> {
        let sorted = chart.map { $0.time }.sorted(by: { $0 < $1 })
        return sorted.count > 2 ? sorted.first!...sorted.last! : Date.now...Date.now//.addingTimeInterval(100)
    }
    
    var isUp: Bool {
        return chart.last?.close ?? .zero > chart.first?.close ?? .zero ? true : false
    }
    
    var dailyChangeIsUp: Bool {
        return priceData.dailyChange > 0
    }
    
    var menuLabel: String {
        let a = priceData.dailyChange < 0 ? "⬇" : "⬆"
        let change = priceData.dailyChange.formatted(.percent.precision(.fractionLength(2)))
        return "\(a)\(change)"
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            LazyVStack {
                HStack(alignment: .lastTextBaseline, spacing: 12) {

//                    Text("24H -")
//                        .font(.system(.caption, design: .monospaced))
                    Spacer()
                    Text(menuLabel)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(dailyChangeIsUp ? Color.green : Color.red)
                        //.offset(x: -8, y: 0)
                    
                    

                    Text(price.formatted(.currency(code: "usd")))
                }

            }
            .foregroundColor(Color.text)
            .font(.system(.title, design: .monospaced))
            .fontWeight(.bold)
            .padding(.horizontal, 4)
            
            Chart {
                
                ForEach(chart, id: \.close) {
                    LineMark(x: .value("Date", $0.time), y: .value("Price", $0.close))
                        .foregroundStyle(isUp ? .green : .red)
                }
                
                
                if let l = chart.last {
                    PointMark(
                        x: .value("Date", l.time),
                        y: .value("Price", l.close)
                    )
                    .foregroundStyle(isUp ? .green : .red)
                }

            }
            .background(Color.text.opacity(0.1))
            .chartXScale(domain: xAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartYScale(domain: yAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartYAxis {
              AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                      .foregroundStyle(Color.text.opacity(0.2))
                AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 2))
                  .foregroundStyle(Color.text)
                AxisValueLabel() { // construct Text here
                  if let intValue = value.as(Int.self) {
                    Text("$\(intValue)")
                          .font(.system(.caption2, design: .monospaced)) // style it
                      .foregroundColor(Color.text)
                  }
                }
              }
            }
            .chartXAxis {
              AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                      .foregroundStyle(Color.text.opacity(0.2))
//                AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 2))
//                  .foregroundStyle(Color.text)
                AxisValueLabel() { // construct Text here
                  if let intValue = value.as(Date.self) {
                      switch priceData.chartTime {
                      case .oneMin:
                          Text(intValue.formatted(.dateTime.hour().minute()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .fifteenMin:
                          Text(intValue.formatted(.dateTime.hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .thirtyMin:
                          Text(intValue.formatted(.dateTime.hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .oneHour:
                          Text(intValue.formatted(.dateTime.weekday().hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .sixHours:
                          Text(intValue.formatted(.dateTime.day().month(.abbreviated)))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .twelveHours:
                          Text(intValue.formatted(.dateTime.day().month()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      }
                  }
                }
              }
            }
            .frame(height: 150)
            .padding(4)

            HStack(spacing: 4) {
                Button(action: {
                    priceData.chartTime = .oneMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("1m")
                        .foregroundColor(priceData.chartTime == .oneMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .oneMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .fifteenMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("15m")
                        .foregroundColor(priceData.chartTime == .fifteenMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .fifteenMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .thirtyMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("30m")
                        .foregroundColor(priceData.chartTime == .thirtyMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .thirtyMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .oneHour
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("1hr")
                        .foregroundColor(priceData.chartTime == .oneHour ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .oneHour ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .sixHours
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("6hr")
                        .foregroundColor(priceData.chartTime == .sixHours ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .sixHours ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .twelveHours
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("12hr")
                        .foregroundColor(priceData.chartTime == .twelveHours ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .twelveHours ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            .background(Color.background)
            .font(.system(.subheadline, design: .monospaced))
            
        }
        .modifier(BorderStyle(title: "Market", systemImageName: dailyChangeIsUp ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis", imageColor: Color.text))

    }
    
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.background
                .edgesIgnoringSafeArea(.all)
            MarketView()
                .frame(width: 435, height: 285)
                .environmentObject(PriceData.shared)
            
        }
    }
}
