import Foundation

@MainActor
final class QuotaStore: ObservableObject {
    @Published private(set) var snapshot: QuotaSnapshot = .loading
    @Published private(set) var isRefreshing = false
    @Published var now = Date()

    private let service: CodexQuotaService
    private var refreshTask: Task<Void, Never>?
    private var clockTask: Task<Void, Never>?

    init(service: CodexQuotaService) {
        self.service = service
    }

    func start() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(60))
            }
        }

        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        clockTask?.cancel()
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            snapshot = try await service.fetch()
        } catch let error as QuotaError {
            snapshot = QuotaSnapshot(
                availableCount: snapshot.availableCount,
                fiveHourWindow: snapshot.fiveHourWindow,
                sevenDayWindow: snapshot.sevenDayWindow,
                credits: snapshot.credits,
                fetchedAt: Date(),
                statusMessage: error.localizedDescription
            )
        } catch {
            snapshot = QuotaSnapshot(
                availableCount: snapshot.availableCount,
                fiveHourWindow: snapshot.fiveHourWindow,
                sevenDayWindow: snapshot.sevenDayWindow,
                credits: snapshot.credits,
                fetchedAt: Date(),
                statusMessage: error.localizedDescription
            )
        }
    }
}
