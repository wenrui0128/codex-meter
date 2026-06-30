import Foundation

enum L10n {
    static var isChinese: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
    }

    static var loadingQuota: String { isChinese ? "正在读取额度" : "Loading quota" }
    static var authFileMissing: String { isChinese ? "未找到 ~/.codex/auth.json" : "Could not find ~/.codex/auth.json" }
    static var accessTokenMissing: String { isChinese ? "未找到 tokens.access_token" : "Could not find tokens.access_token" }
    static var unauthorized: String { isChinese ? "401: 凭证失效或没带对 Authorization header" : "401: credentials expired or Authorization header is incorrect" }
    static var invalidResponse: String { isChinese ? "接口返回格式无法解析" : "Could not parse the API response" }
    static func httpFailed(_ statusCode: Int) -> String { isChinese ? "HTTP \(statusCode): 请求失败" : "HTTP \(statusCode): request failed" }

    static var fiveHourQuota: String { isChinese ? "5 小时额度" : "5-hour quota" }
    static var sevenDayQuota: String { isChinese ? "7 天额度" : "7-day quota" }
    static var quota: String { isChinese ? "额度" : "Quota" }
    static var codexQuota: String { "CodexMeter" }
    static var lastUpdated: String { isChinese ? "上次刷新" : "Last updated" }
    static var fiveHourRemaining: String { isChinese ? "5小时剩余" : "5h remaining" }
    static var resetCards: String { isChinese ? "重置卡" : "Reset cards" }
    static var available: String { isChinese ? "可用" : "available" }
    static var fiveHourRefresh: String { isChinese ? "5小时刷新" : "5h reset" }
    static var waitingForSync: String { isChinese ? "等待同步" : "Waiting to sync" }
    static var refresh: String { isChinese ? "刷新" : "Refresh" }
    static var refreshing: String { isChinese ? "正在刷新" : "Refreshing" }
    static var autoRefresh: String { isChinese ? "每 60 秒自动刷新" : "Auto-refresh every 60 seconds" }
    static var quit: String { isChinese ? "退出" : "Quit" }
    static var resetCredit: String { isChinese ? "重置卡" : "Reset credit" }
    static var unknown: String { isChinese ? "未知" : "unknown" }
    static func used(_ value: String) -> String { isChinese ? "已用 \(value)" : "Used \(value)" }

    static func remaining(days: Int, hours: Int, minutes: Int) -> String {
        if days > 0 {
            return isChinese ? "\(days)天 \(hours)小时" : "\(days)d \(hours)h"
        }
        if hours > 0 {
            return isChinese ? "\(hours)小时 \(minutes)分" : "\(hours)h \(minutes)m"
        }
        return isChinese ? "\(minutes)分" : "\(minutes)m"
    }

    static func compactRemaining(days: Int, hours: Int, minutes: Int) -> String {
        if days > 0 {
            return isChinese ? "\(days)天\(hours)时" : "\(days)d \(hours)h"
        }
        if hours > 0 {
            return isChinese ? "\(hours)时\(minutes)分" : "\(hours)h \(minutes)m"
        }
        return isChinese ? "\(minutes)分" : "\(minutes)m"
    }
}
