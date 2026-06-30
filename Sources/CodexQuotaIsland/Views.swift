import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: QuotaStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let message = store.snapshot.statusMessage {
                StatusBanner(message: message)
            }

            quotaSummary
            controls

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(store.snapshot.credits) { credit in
                        CreditRow(credit: credit, now: store.now)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .padding(18)
        .frame(width: 380, height: 520)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.cyan.opacity(0.9), Color.indigo.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.codexQuota)
                    .font(.system(size: 17, weight: .semibold))
                Text("\(L10n.lastUpdated) \(store.snapshot.fetchedAt.shanghaiTimeString)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(store.snapshot.fiveHourWindow?.remainingPercent.map { "\($0)%" } ?? "--")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(L10n.fiveHourRemaining)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quotaSummary: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                QuotaWindowCard(
                    window: store.snapshot.fiveHourWindow,
                    now: store.now,
                    accent: .cyan,
                    icon: "timer"
                )
                QuotaWindowCard(
                    window: store.snapshot.sevenDayWindow,
                    now: store.now,
                    accent: .indigo,
                    icon: "calendar"
                )
            }

            HStack(spacing: 10) {
                CompactMetric(
                    title: L10n.resetCards,
                    value: store.snapshot.availableCount.map(String.init) ?? "--",
                    caption: L10n.available
                )
                CompactMetric(
                    title: L10n.fiveHourRefresh,
                    value: store.snapshot.fiveHourWindow?.resetAt?.compactRemainingDescription(from: store.now) ?? "--",
                    caption: store.snapshot.fiveHourWindow?.resetAt?.shortShanghaiTimeString ?? L10n.waitingForSync
                )
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: store.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderedProminent)
            .help(L10n.refresh)
            .disabled(store.isRefreshing)

            Text(store.isRefreshing ? L10n.refreshing : L10n.autoRefresh)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .frame(width: 18, height: 18)
            }
            .help(L10n.quit)
        }
    }
}

struct QuotaWindowCard: View {
    var window: QuotaWindow?
    var now: Date
    var accent: Color
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(window?.title ?? L10n.quota, systemImage: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(window?.remainingPercent.map { "\($0)%" } ?? "--")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            ProgressView(value: progressValue)
                .tint(accent)

            HStack {
                Text(L10n.used(window?.usedPercent.map { "\($0)%" } ?? "--"))
                Spacer()
                Text(window?.resetAt?.compactRemainingDescription(from: now) ?? "--")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(accent.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(accent.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var progressValue: Double {
        Double(window?.remainingPercent ?? 0) / 100.0
    }
}

struct CompactMetric: View {
    var title: String
    var value: String
    var caption: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(caption)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }
}

struct CreditRow: View {
    var credit: ResetCredit
    var now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(credit.title ?? L10n.resetCredit)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    Text(credit.status ?? L10n.unknown)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor)
                }

                Spacer()

                Text(remainingText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Label(grantedText, systemImage: "plus.circle")
                Spacer(minLength: 10)
                Label(expiresText, systemImage: "clock")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var statusColor: Color {
        switch credit.status?.lowercased() {
        case "available":
            return .green
        case "expired":
            return .secondary
        default:
            return .orange
        }
    }

    private var grantedText: String {
        credit.grantedAt?.shanghaiTimeString ?? "--"
    }

    private var expiresText: String {
        credit.expiresAt?.shanghaiTimeString ?? "--"
    }

    private var remainingText: String {
        guard let expiresAt = credit.expiresAt else {
            return "--"
        }

        return expiresAt.remainingDescription(from: now)
    }
}

struct StatusBanner: View {
    var message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.yellow.opacity(0.14))
        )
        .foregroundStyle(.yellow)
    }
}

private extension Date {
    var shanghaiTimeString: String {
        DateFormatter.shanghaiFull.string(from: self)
    }

    var shortShanghaiTimeString: String {
        DateFormatter.shanghaiShort.string(from: self)
    }

    func remainingDescription(from now: Date) -> String {
        let seconds = max(0, Int(timeIntervalSince(now)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        if days > 0 {
            return L10n.remaining(days: days, hours: hours, minutes: minutes)
        }
        return L10n.remaining(days: days, hours: hours, minutes: minutes)
    }

    func compactRemainingDescription(from now: Date) -> String {
        let seconds = max(0, Int(timeIntervalSince(now)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        if days > 0 {
            return L10n.compactRemaining(days: days, hours: hours, minutes: minutes)
        }
        return L10n.compactRemaining(days: days, hours: hours, minutes: minutes)
    }
}

private extension DateFormatter {
    static var shanghaiFull: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = L10n.isChinese ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd HH:mm:ss 'CST'"
        return formatter
    }

    static var shanghaiShort: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = L10n.isChinese ? "MM-dd HH:mm" : "MMM d HH:mm"
        return formatter
    }
}
