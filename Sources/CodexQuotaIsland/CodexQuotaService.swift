import Foundation

actor CodexQuotaService {
    private let usageEndpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
    private let resetCreditsEndpoint = URL(string: "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits")!
    private let authURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/auth.json")

    func fetch() async throws -> QuotaSnapshot {
        let token = try readAccessToken()

        let usageObject = try await requestJSON(from: usageEndpoint, token: token)
        let resetCreditsObject = try await requestJSON(from: resetCreditsEndpoint, token: token)
        return try parseSnapshot(usageObject: usageObject, resetCreditsObject: resetCreditsObject)
    }

    private func requestJSON(from url: URL, token: String) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexMeter", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw QuotaError.invalidResponse
            }
            guard http.statusCode != 401 else {
                throw QuotaError.unauthorized
            }
            guard (200..<300).contains(http.statusCode) else {
                throw QuotaError.requestFailed(L10n.httpFailed(http.statusCode))
            }

            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw QuotaError.invalidResponse
            }

            return object
        } catch let error as QuotaError {
            throw error
        } catch {
            throw QuotaError.requestFailed(error.localizedDescription)
        }
    }

    private func readAccessToken() throws -> String {
        guard FileManager.default.fileExists(atPath: authURL.path) else {
            throw QuotaError.authFileMissing
        }

        let data = try Data(contentsOf: authURL)
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tokens = object["tokens"] as? [String: Any],
            let accessToken = tokens["access_token"] as? String,
            !accessToken.isEmpty
        else {
            throw QuotaError.accessTokenMissing
        }

        return accessToken
    }

    private func parseSnapshot(usageObject: [String: Any], resetCreditsObject: [String: Any]) throws -> QuotaSnapshot {
        let availableCount = intValue(resetCreditsObject["available_count"])
        let credits = extractCredits(from: resetCreditsObject).map { creditObject in
            ResetCredit(
                status: creditObject["status"] as? String,
                title: creditObject["title"] as? String,
                grantedAt: parseDate(creditObject["granted_at"]),
                expiresAt: parseDate(creditObject["expires_at"])
            )
        }
        let rateLimit = usageObject["rate_limit"] as? [String: Any]
        let allowed = rateLimit?["allowed"] as? Bool
        let limitReached = rateLimit?["limit_reached"] as? Bool
        let windows = [
            parseWindow(rateLimit?["primary_window"], fallbackTitle: L10n.fiveHourQuota, allowed: allowed, limitReached: limitReached),
            parseWindow(rateLimit?["secondary_window"], fallbackTitle: L10n.sevenDayQuota, allowed: allowed, limitReached: limitReached)
        ].compactMap { $0 }

        return QuotaSnapshot(
            availableCount: availableCount,
            fiveHourWindow: windows.first { $0.windowSeconds == 18_000 } ?? windows.first,
            sevenDayWindow: windows.first { $0.windowSeconds == 604_800 } ?? windows.dropFirst().first,
            credits: credits,
            fetchedAt: Date(),
            statusMessage: nil
        )
    }

    private func parseWindow(
        _ value: Any?,
        fallbackTitle: String,
        allowed: Bool?,
        limitReached: Bool?
    ) -> QuotaWindow? {
        guard let object = value as? [String: Any] else {
            return nil
        }

        let windowSeconds = intValue(object["limit_window_seconds"])
        let resetAt = parseDate(object["reset_at"])
        let title: String

        switch windowSeconds {
        case 18_000:
            title = L10n.fiveHourQuota
        case 604_800:
            title = L10n.sevenDayQuota
        default:
            title = fallbackTitle
        }

        return QuotaWindow(
            title: title,
            usedPercent: intValue(object["used_percent"]),
            windowSeconds: windowSeconds,
            resetAt: resetAt,
            allowed: allowed,
            limitReached: limitReached
        )
    }

    private func extractCredits(from object: [String: Any]) -> [[String: Any]] {
        for key in ["credits", "data", "items", "rate_limit_reset_credits"] {
            if let credits = object[key] as? [[String: Any]] {
                return credits
            }
        }

        let mappedValues = object.values.compactMap { $0 as? [String: Any] }
        let looksLikeCredits = mappedValues.allSatisfy { value in
            value["status"] != nil || value["title"] != nil || value["granted_at"] != nil || value["expires_at"] != nil
        }

        return looksLikeCredits ? mappedValues : []
    }

    private func parseDate(_ value: Any?) -> Date? {
        if let seconds = intValue(value) {
            let timestamp = seconds > 10_000_000_000 ? TimeInterval(seconds) / 1000 : TimeInterval(seconds)
            return Date(timeIntervalSince1970: timestamp)
        }

        if let seconds = value as? TimeInterval {
            let timestamp = seconds > 10_000_000_000 ? seconds / 1000 : seconds
            return Date(timeIntervalSince1970: timestamp)
        }

        guard let string = value as? String, !string.isEmpty else {
            return nil
        }

        if let date = ISO8601DateFormatter.internetWithFractionalSeconds.date(from: string) {
            return date
        }

        if let date = ISO8601DateFormatter.internet.date(from: string) {
            return date
        }

        return DateFormatter.fallbackInternet.date(from: string)
    }

    private func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? Double {
            return Int(value)
        }
        if let value = value as? String {
            return Int(value)
        }
        return nil
    }
}

private extension ISO8601DateFormatter {
    static var internet: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    static var internetWithFractionalSeconds: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

private extension DateFormatter {
    static var fallbackInternet: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter
    }
}
