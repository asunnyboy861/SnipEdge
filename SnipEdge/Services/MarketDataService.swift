import Foundation

actor MarketDataService {
    static let shared = MarketDataService()

    private var cache: [String: (bars: [Bar], fetchedAt: Date)] = [:]
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15
        session = URLSession(configuration: configuration)
    }

    func bars(symbol: String, timeframe: String?) async -> [Bar] {
        let key = "\(symbol.uppercased())|\(timeframe ?? "1D")"
        if let cached = cache[key], Date().timeIntervalSince(cached.fetchedAt) < 300 {
            return cached.bars
        }
        guard let url = buildURL(symbol: symbol, timeframe: timeframe) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else { return [] }
            let bars = parse(data)
            if !bars.isEmpty {
                cache[key] = (bars, Date())
            }
            return bars
        } catch {
            return []
        }
    }

    private func buildURL(symbol: String, timeframe: String?) -> URL? {
        let interval: String
        let range: String
        switch timeframe ?? "1D" {
        case "1m": interval = "1m"; range = "1d"
        case "5m": interval = "5m"; range = "5d"
        case "15m": interval = "15m"; range = "1mo"
        case "1H": interval = "60m"; range = "3mo"
        case "4H": interval = "60m"; range = "6mo"
        case "1W": interval = "1wk"; range = "5y"
        default: interval = "1d"; range = "2y"
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "query1.finance.yahoo.com"
        components.path = "/v8/finance/chart/\(symbol)"
        components.queryItems = [
            URLQueryItem(name: "range", value: range),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "includePrePost", value: "false")
        ]
        return components.url
    }

    private func parse(_ data: Data) -> [Bar] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chart = root["chart"] as? [String: Any],
            let results = chart["result"] as? [[String: Any]],
            let first = results.first,
            let timestamps = first["timestamp"] as? [Double],
            let indicators = first["indicators"] as? [String: Any],
            let quotes = indicators["quote"] as? [[String: Any]],
            let quote = quotes.first
        else { return [] }

        guard
            let opens = quote["open"] as? [Any],
            let highs = quote["high"] as? [Any],
            let lows = quote["low"] as? [Any],
            let closes = quote["close"] as? [Any],
            let volumes = quote["volume"] as? [Any]
        else { return [] }

        var bars: [Bar] = []
        for index in timestamps.indices {
            guard index < opens.count, index < highs.count, index < lows.count, index < closes.count else { continue }
            guard
                let open = opens[index] as? Double,
                let high = highs[index] as? Double,
                let low = lows[index] as? Double,
                let close = closes[index] as? Double
            else { continue }
            let volume = volumes[index] as? Double ?? 0
            bars.append(Bar(date: Date(timeIntervalSince1970: timestamps[index]), open: open, high: high, low: low, close: close, volume: volume))
        }
        return bars
    }
}
