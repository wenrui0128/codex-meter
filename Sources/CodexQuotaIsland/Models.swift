import Foundation

struct QuotaSnapshot: Equatable {
    var availableCount: Int?
    var fiveHourWindow: QuotaWindow?
    var sevenDayWindow: QuotaWindow?
    var credits: [ResetCredit]
    var fetchedAt: Date
    var statusMessage: String?

    static let loading = QuotaSnapshot(
        availableCount: nil,
        fiveHourWindow: nil,
        sevenDayWindow: nil,
        credits: [],
        fetchedAt: Date(),
        statusMessage: L10n.loadingQuota
    )
}

struct QuotaWindow: Equatable {
    var title: String
    var usedPercent: Int?
    var windowSeconds: Int?
    var resetAt: Date?
    var allowed: Bool?
    var limitReached: Bool?

    var remainingPercent: Int? {
        usedPercent.map { max(0, min(100, 100 - $0)) }
    }
}

struct ResetCredit: Identifiable, Equatable {
    let id = UUID()
    var status: String?
    var title: String?
    var grantedAt: Date?
    var expiresAt: Date?
}

enum QuotaError: LocalizedError, Equatable {
    case authFileMissing
    case accessTokenMissing
    case unauthorized
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .authFileMissing:
            return L10n.authFileMissing
        case .accessTokenMissing:
            return L10n.accessTokenMissing
        case .unauthorized:
            return L10n.unauthorized
        case .invalidResponse:
            return L10n.invalidResponse
        case .requestFailed(let message):
            return message
        }
    }
}
