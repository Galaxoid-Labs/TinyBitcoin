//
//  PriceData.swift
//  TinyBitcoin
//
//  Created by Jacob Davis on 6/13/22.
//

import Foundation
import Starscream

class PriceData: ObservableObject {
    
    @Published var lastPrice: Double = .zero
    @Published var dailyChange: Double = .zero
    @Published var chart: [CandleMark] = []
    @Published var chartTime: ChartTime = .oneMin
    
    @Published var tickerSocketConnected: Bool = false
    @Published var candleSocketConnected: Bool = false
    
    private var tickerSocket: WebSocket?
    private var candleSocket: WebSocket?
    
    public enum ChartTime: String, CaseIterable {
        case oneMin = "1m"
        case fifteenMin = "15m"
        case thirtyMin = "30m"
        case oneHour = "1h"
        case sixHours = "6h"
        case twelveHours = "12h"
    }
    
    public static let shared = PriceData()
    
    private init() {}
    
    @MainActor
    func connectTickerSocket() async {
        
        await disconnectTickerSocket()
        
        var request = URLRequest(url: URL(string: "wss://api-pub.bitfinex.com/ws/2")!)
        request.timeoutInterval = 5
        tickerSocket = WebSocket(request: request)
        
        tickerSocket?.onEvent = { [weak self] event in
            
            switch event {
            case .connected(_):
                self?.tickerSocketConnected = true
                
                let req = ["event":"subscribe","channel":"ticker", "symbol": "tBTCUSD"]
                do {
                    let data = try JSONEncoder().encode(req)
                    self?.tickerSocket?.write(data: data)
                } catch {
                    print(error)
                }
                
            case .disconnected(let reason, let code):
                self?.tickerSocketConnected = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                do {
                    guard let data = string.data(using: .utf8) else {
                        return
                    }
                    guard let array = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                        return
                    }
                    
                    guard let _ = array.first as? Int else { // ChannelId
                        return
                    }
                    
                    if array.count > 1 {
                        guard let dataAray = array[1] as? [Any] else {
                            return
                        }
                        
                        guard let lastPrice = dataAray[6] as? Double else {
                            return
                        }
                        
                        self?.lastPrice = lastPrice
                        
                        guard let dailyChange = dataAray[5] as? Double else {
                            return
                        }
                        
                        self?.dailyChange = dailyChange
                    }
                } catch {
                    print(error)
                }
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self?.tickerSocketConnected = false
            case .error(_):
                self?.tickerSocketConnected = false
            }
        }
        tickerSocket?.connect()
    }
    
    @MainActor
    func disconnectTickerSocket() async {
        tickerSocket?.forceDisconnect()
    }
    
    @MainActor
    func connectCandleSocket() async {
        
        await disconnectCandleSocket()
        
        var request = URLRequest(url: URL(string: "wss://api-pub.bitfinex.com/ws/2")!)
        request.timeoutInterval = 5
        candleSocket = WebSocket(request: request)
        
        candleSocket?.onEvent = { [weak self] event in
            
            switch event {
            case .connected(_):
                self?.candleSocketConnected = true
                
                let req = ["event":"subscribe","channel":"candles", "key": "trade:\(self?.chartTime.rawValue ?? "1m"):tBTCUSD"]
                do {
                    let data = try JSONEncoder().encode(req)
                    self?.candleSocket?.write(data: data)
                } catch {
                    print(error)
                }
                
            case .disconnected(let reason, let code):
                self?.candleSocketConnected = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                //print("Received text: \(string)")
                do {
                    guard let data = string.data(using: .utf8) else {
                        return
                    }
                    guard let array = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                        return
                    }
                    
                    guard let _ = array.first as? Int else { // channel ID
                        return
                    }
                    
                    if array.count > 1 {
                        
                        if let snap = array[1] as? [[Any]] {
                            
                            let chart = snap.compactMap({
                                if let time = $0[0] as? Int, let open = $0[1] as? Double, let close = $0[2] as? Double, let high = $0[3] as? Double, let low = $0[4] as? Double {
                                    return CandleMark(id: time, time: Date(timeIntervalSince1970: TimeInterval(time) / 1000),
                                                      open: open, close: close, high: high, low: low)
                                }
                                return nil
                            })
                            
                            self?.chart = Array(chart.prefix(upTo: 40).sorted { $0.time < $1.time })
                            
                        } else if let upd = array[1] as? [Any] {
                            
                            if let time = upd[0] as? Int, let open = upd[1] as? Double, let close = upd[2] as? Double, let high = upd[3] as? Double, let low = upd[4] as? Double {
                                let c = CandleMark(id: time, time: Date(timeIntervalSince1970: TimeInterval(time) / 1000), open: open, close: close, high: high, low: low)
                                
                                if let index = self?.chart.firstIndex(where: { $0.id == c.id }) {
                                    self?.chart[index] = c
                                } else {
                                    self?.chart.removeFirst()
                                    self?.chart.append(c)
                                }
                            }
                            
                        }
                        
                    }
                    
                } catch {
                    print(error)
                }
                
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self?.candleSocketConnected = false
            case .error(_):
                self?.candleSocketConnected = false
            }
            
        }
        
        candleSocket?.connect()
        
    }
    
    @MainActor
    func disconnectCandleSocket() async {
        candleSocket?.forceDisconnect()
    }
}

public struct CandleMark: Hashable, Equatable {
    public let id: Int // date stamp
    public let time: Date
    public let open: Double
    public let close: Double
    public let high: Double
    public let low: Double
    public static func == (lhs: CandleMark, rhs: CandleMark) -> Bool {
        return lhs.id == rhs.id
    }
}
