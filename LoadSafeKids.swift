import SwiftUI
#if canImport(Charts)
import Charts
#endif


extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

private enum CheckInAlert: Identifiable {
    case checkIn(CheckIn)
    case injury(InjuryReport)

    var id: String {
        switch self {
        case .checkIn(let checkIn):
            return "checkIn-\(checkIn.id)"
        case .injury(let injury):
            return "injury-\(injury.id)"
        }
    }
}

struct TrainSafeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: 0xEEF2F7), location: 0.0),
                    .init(color: Color(hex: 0xDDE7F3), location: 0.35),
                    .init(color: Color(hex: 0xC7D6EB), location: 0.7),
                    .init(color: Color(hex: 0xAFC5E2), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: 0xC7D6EB).opacity(0.4), location: 0.0),
                    .init(color: Color(hex: 0xAFC5E2).opacity(0.18), location: 0.45),
                    .init(color: Color(hex: 0xAFC5E2).opacity(0.04), location: 1.0)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }
}

enum TrainSafeTilePalette {
    static let dashboard = Color(hex: 0xCFE8FF)
    static let log = Color(hex: 0xDFF5CF)
    static let checkIn = Color(hex: 0xFFD6E8)
    static let growth = Color(hex: 0xFFE5C4)
}

private struct TrainSafeScreenBackgroundModifier: ViewModifier {
    var overlay: Color?

    func body(content: Content) -> some View {
        ZStack {
            TrainSafeBackground()
            if let overlay {
                LinearGradient(
                    colors: [
                        overlay.opacity(0.32),
                        overlay.opacity(0.22),
                        overlay.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            content
        }
    }
}

extension View {
    func trainSafeScreenBackground(overlay: Color? = nil) -> some View {
        modifier(TrainSafeScreenBackgroundModifier(overlay: overlay))
    }
}

private struct TrainSafeGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var fillColor: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func trainSafeGlassCard(color: Color, cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        modifier(TrainSafeGlassCardModifier(cornerRadius: cornerRadius, padding: padding, fillColor: color))
    }

    func trainSafeVibrantText() -> some View {
        foregroundStyle(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
    }

    func trainSafeInputFieldBackground(cornerRadius: CGFloat = 14) -> some View {
        padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            )
    }

    func trainSafeEntryTile(color: Color, cornerRadius: CGFloat = 20) -> some View {
        modifier(TrainSafeEntryTileModifier(cornerRadius: cornerRadius, color: color))
    }
}

private struct TrainSafeEntryTileModifier: ViewModifier {
    var cornerRadius: CGFloat
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Models
struct Session: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var date: Date
    var sport: String
    var durationMin: Int
    var rpe: Int
    var notes: String = ""
}

struct CheckIn: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var date: Date
    var soreness: Int
    var fatigue: Int
    var sleepHours: Double
    var notes: String = ""
}

struct HeightEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var date: Date
    var heightCm: Double
}

enum GrowthReference: String, CaseIterable, Identifiable {
    case boy
    case girl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boy: return "Boys"
        case .girl: return "Girls"
        }
    }

    var ageRangeDescription: String {
        switch self {
        case .boy: return "Ages 12–16"
        case .girl: return "Ages 9–13"
        }
    }

    var monthlyThresholds: (low: Double, moderate: Double) {
        switch self {
        case .boy: return (0.50, 0.83)
        case .girl: return (0.45, 0.57)
        }
    }
}

enum GrowthVelocityBand: String, CaseIterable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        }
    }

    func summary(reference: GrowthReference) -> String {
        switch self {
        case .low:
            return "Low growth for \(reference.displayName.lowercased())."
        case .moderate:
            return "Moderate growth for \(reference.displayName.lowercased())."
        case .high:
            return "High growth (PHV) for \(reference.displayName.lowercased())."
        }
    }

    func guidance(reference: GrowthReference) -> String {
        switch self {
        case .low:
            return "Stay patient — steady nutrition and sleep help growth catch up."
        case .moderate:
            return "Nice steady progress — keep building strength and skills."
        case .high:
            return "Bodies feel extra sensitive during growth spurts, so keep load gentle and focus on recovery."
        }
    }
}

struct GrowthVelocitySample: Identifiable {
    let id = UUID()
    let periodStart: Date
    let periodEnd: Date
    let changeCm: Double
    let daysBetween: Int
    let cmPerMonth: Double
    let cmPerYear: Double
    let band: GrowthVelocityBand
}

struct InjuryReport: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var dateOfInjury: Date
    var injuryLocation: String
    var mechanism: String
    var severity: Double
    var swelling: Bool
    var weightBearing: Bool
    var seenPhysio: Bool
    var notes: String = ""
}

enum SportOption: String, CaseIterable, Identifiable {
    case cricket
    case running
    case tennis
    case basketball
    case soccer
    case footy
    case cycling
    case fieldHockey
    case swimming
    case volleyball
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cricket: return "Cricket"
        case .running: return "Running"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .footy: return "Footy"
        case .cycling: return "Cycling"
        case .fieldHockey: return "Field Hockey"
        case .swimming: return "Swimming"
        case .volleyball: return "Volleyball"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cricket: return "🏏"
        case .running: return "🏃"
        case .tennis: return "🎾"
        case .basketball: return "🏀"
        case .soccer: return "⚽️"
        case .footy: return "🏉"
        case .cycling: return "🚴"
        case .fieldHockey: return "🏑"
        case .swimming: return "🏊"
        case .volleyball: return "🏐"
        case .other: return "➕"
        }
    }

    func resolvedSport(customName: String) -> String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if self == .other {
            return trimmed.isEmpty ? displayName : trimmed
        }
        return displayName
    }
}

// MARK: - Utilities
extension Date {
    static var today: Date { Calendar.current.startOfDay(for: Date()) }
    func isoDay() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

func sessionLoad(_ s: Session) -> Int { s.durationMin * s.rpe }

func dailyLoadMap(sessions: [Session]) -> [String:Int] {
    var map: [String:Int] = [:]
    for s in sessions {
        let key = s.date.isoDay()
        map[key, default: 0] += sessionLoad(s)
    }
    return map
}

func dateRange(_ start: Date, _ end: Date) -> [Date] {
    var res: [Date] = []
    var d = Calendar.current.startOfDay(for: start)
    let end = Calendar.current.startOfDay(for: end)
    while d <= end {
        res.append(d)
        d = Calendar.current.date(byAdding: .day, value: 1, to: d)!
    }
    return res
}

/// ACWR = mean last 7 days / mean last 28 days (simple version)
func computeACWR(dailyMap: [String:Int], endDate: Date) -> Double {
    let cal = Calendar.current
    let end = cal.startOfDay(for: endDate)
    let d7Start = cal.date(byAdding: .day, value: -6, to: end)!
    let d28Start = cal.date(byAdding: .day, value: -27, to: end)!

    let dates7 = dateRange(d7Start, end)
    let dates28 = dateRange(d28Start, end)

    let sum7 = dates7.reduce(0) { $0 + (dailyMap[$1.isoDay()] ?? 0) }
    let sum28 = dates28.reduce(0) { $0 + (dailyMap[$1.isoDay()] ?? 0) }

    let mean7 = Double(sum7) / Double(dates7.count)
    let mean28 = Double(sum28) / Double(dates28.count)
    guard mean28 > 0 else { return 0 }
    return mean7 / mean28
}

private func monthlyVelocity(for changeCm: Double, daysBetween: Int) -> Double {
    guard daysBetween > 0 else { return 0 }
    let perDay = changeCm / Double(daysBetween)
    return perDay * 30.0
}

private func yearlyVelocity(for changeCm: Double, daysBetween: Int) -> Double {
    guard daysBetween > 0 else { return 0 }
    let perDay = changeCm / Double(daysBetween)
    return perDay * 365.0
}

func growthVelocitySamples(heights: [HeightEntry], reference: GrowthReference) -> [GrowthVelocitySample] {
    let sorted = heights.sorted { $0.date < $1.date }
    guard sorted.count >= 2 else { return [] }
    let thresholds = reference.monthlyThresholds
    var samples: [GrowthVelocitySample] = []
    let calendar = Calendar.current

    for index in 1..<sorted.count {
        let previous = sorted[index - 1]
        let current = sorted[index]
        guard let days = calendar.dateComponents([.day], from: previous.date, to: current.date).day else { continue }
        let clampedDays = max(days, 1)
        let changeCm = current.heightCm - previous.heightCm
        let cmPerMonth = monthlyVelocity(for: changeCm, daysBetween: clampedDays)
        let normalized = max(cmPerMonth, 0)
        let band: GrowthVelocityBand
        if normalized < thresholds.low {
            band = .low
        } else if normalized <= thresholds.moderate {
            band = .moderate
        } else {
            band = .high
        }
        let sample = GrowthVelocitySample(
            periodStart: previous.date,
            periodEnd: current.date,
            changeCm: changeCm,
            daysBetween: clampedDays,
            cmPerMonth: cmPerMonth,
            cmPerYear: yearlyVelocity(for: changeCm, daysBetween: clampedDays),
            band: band
        )
        samples.append(sample)
    }

    return samples
}

func latestGrowthVelocityBand(heights: [HeightEntry], reference: GrowthReference) -> GrowthVelocityBand? {
    growthVelocitySamples(heights: heights, reference: reference).last?.band
}

enum GrowthFormatting {
    static let monthly: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let yearly: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

enum RiskLevel: String { case green, yellow, red }

func riskScore(acwr: Double, growthBand: GrowthVelocityBand?) -> (RiskLevel, String) {
    var score = 0
    if acwr >= 1.5 { score += 2 }
    else if acwr >= 1.2 { score += 1 }

    if let band = growthBand, band == .high {
        score += 1
    }

    if score >= 3 { return (.red, "High overload risk – reduce load & prioritise recovery.") }
    if score == 2 { return (.yellow, "Moderate risk – monitor symptoms, consider lighter sessions.") }
    return (.green, "Load looks OK – continue as planned.")
}

// MARK: - Persistence
final class DataStore: ObservableObject {
    @Published var athleteName: String = "Alex"
    @Published var sessions: [Session] = []
    @Published var checkins: [CheckIn] = []
    @Published var heights: [HeightEntry] = []
    @Published var injuries: [InjuryReport] = []

    private let K_sessions = "loadsafekids_sessions"
    private let K_checkins = "loadsafekids_checkins"
    private let K_heights = "loadsafekids_heights"
    private let K_profile = "loadsafekids_profile"
    private let K_injuries = "loadsafekids_injuries"

    init() {
        load()
        if sessions.isEmpty && checkins.isEmpty && heights.isEmpty {
            seedDemo()
        }
    }

    func load() {
        let dec = JSONDecoder()
        if let d = UserDefaults.standard.data(forKey: K_sessions), let v = try? dec.decode([Session].self, from: d) { sessions = v }
        if let d = UserDefaults.standard.data(forKey: K_checkins), let v = try? dec.decode([CheckIn].self, from: d) { checkins = v }
        if let d = UserDefaults.standard.data(forKey: K_heights), let v = try? dec.decode([HeightEntry].self, from: d) { heights = v }
        if let name = UserDefaults.standard.string(forKey: K_profile) { athleteName = name }
        if let d = UserDefaults.standard.data(forKey: K_injuries), let v = try? dec.decode([InjuryReport].self, from: d) { injuries = v }
    }

    func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(sessions) { UserDefaults.standard.set(d, forKey: K_sessions) }
        if let d = try? enc.encode(checkins) { UserDefaults.standard.set(d, forKey: K_checkins) }
        if let d = try? enc.encode(heights) { UserDefaults.standard.set(d, forKey: K_heights) }
        if let d = try? enc.encode(injuries) { UserDefaults.standard.set(d, forKey: K_injuries) }
        UserDefaults.standard.set(athleteName, forKey: K_profile)
    }

    func resetAll() {
        sessions.removeAll(); checkins.removeAll(); heights.removeAll(); save()
    }

    private func seedDemo() {
        let today = Date.today
        sessions = [
            Session(date: today, sport: SportOption.cricket.displayName, durationMin: 60, rpe: 6, notes: "nets"),
            Session(date: today, sport: SportOption.running.displayName, durationMin: 30, rpe: 5, notes: "easy jog")
        ]
        checkins = [
            CheckIn(date: today, soreness: 4, fatigue: 4, sleepHours: 8, notes: "")
        ]
        heights = [
            HeightEntry(date: Calendar.current.date(byAdding: .day, value: -32, to: today)!, heightCm: 152),
            HeightEntry(date: today, heightCm: 154)
        ]
        save()
    }
}

extension DataStore {
    var displayAthleteName: String {
        let trimmed = athleteName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Athlete" : trimmed
    }
}

// MARK: - Export Scope
enum ExportScope: Equatable {
    case all
    case lastMonth
    case lastSixMonths
    case lastYear
    case range(start: Date, end: Date)

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)

        switch self {
        case .all:
            return true
        case .lastMonth:
            if let lower = calendar.date(byAdding: .month, value: -1, to: Date()) {
                return target >= calendar.startOfDay(for: lower)
            }
            return true
        case .lastSixMonths:
            if let lower = calendar.date(byAdding: .month, value: -6, to: Date()) {
                return target >= calendar.startOfDay(for: lower)
            }
            return true
        case .lastYear:
            if let lower = calendar.date(byAdding: .year, value: -1, to: Date()) {
                return target >= calendar.startOfDay(for: lower)
            }
            return true
        case .range(let start, let end):
            let normalizedStart = calendar.startOfDay(for: min(start, end))
            let normalizedEnd = calendar.startOfDay(for: max(start, end))
            return target >= normalizedStart && target <= normalizedEnd
        }
    }

    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        switch self {
        case .all:
            return "All data"
        case .lastMonth:
            return "Last month"
        case .lastSixMonths:
            return "Last 6 months"
        case .lastYear:
            return "Last year"
        case .range(let start, let end):
            let startText = formatter.string(from: start)
            let endText = formatter.string(from: end)
            return "Range: \(startText) – \(endText)"
        }
    }
}

// MARK: - App Entry
@main
struct TrainSafeApp: App {
    @StateObject private var store = DataStore()
    @AppStorage("TrainSafe_hasLoggedIn") private var hasCompletedLogin = false
    @AppStorage("TrainSafe_shouldShowWelcome") private var shouldShowWelcome = false

    init() {
#if canImport(UIKit)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
#endif
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedLogin {
                RootView(onLogout: {
                    hasCompletedLogin = false
                    shouldShowWelcome = false
                })
                .environmentObject(store)
            } else if shouldShowWelcome {
                WelcomeScreen {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        hasCompletedLogin = true
                        shouldShowWelcome = false
                    }
                }
                .environmentObject(store)
            } else {
                TitleScreen {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        shouldShowWelcome = true
                    }
                }
                .environmentObject(store)
            }
        }
    }
}

// MARK: - Root & Tabs
struct RootView: View {
    let onLogout: () -> Void
    @EnvironmentObject var store: DataStore
    @State private var showLogoutConfirmation = false
    @State private var showLearnMore = false
    @AppStorage("TrainSafe_growthEnabled") private var growthTrackingEnabled = false
    @State private var shareURL: URL? = nil
    @State private var shareSheetPresented = false
    @State private var showShareError = false
    @State private var showExportOptions = false
    @State private var exportScope: ExportScope = .all

    static let sleepFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let heightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    var body: some View {
        NavigationStack {
            TabView {
                DashboardView(growthTrackingEnabled: $growthTrackingEnabled)
                    .tabItem { Label("Dashboard", systemImage: "gauge.medium") }
                LogSessionView()
                    .tabItem { Label("Log", systemImage: "square.and.pencil") }
                CheckInView()
                    .tabItem { Label("Check-In/Log Injury", systemImage: "checkmark.circle") }
                if growthTrackingEnabled {
                    GrowthView(isEnabled: growthTrackingEnabled)
                        .tabItem { Label("Growth", systemImage: "ruler") }
                }
            }
            .background(Color.clear)
            .navigationTitle("TrainSafe")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Profile for \(store.displayAthleteName)")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showLearnMore = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Learn more about TrainSafe")
                    Button {
                        showExportOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .trainSafeScreenBackground(overlay: TrainSafeTilePalette.dashboard)
        .confirmationDialog("Sign out of \(store.displayAthleteName)?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out \(store.displayAthleteName)", role: .destructive) {
                showLogoutConfirmation = false
                onLogout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\(store.displayAthleteName) will be logged out and returned to the login screen. Your saved training data will remain on this device.")
        }
        .sheet(isPresented: $showLearnMore) {
            LearnMoreView()
        }
        .sheet(isPresented: $showExportOptions) {
            ExportScopeSelector(initialScope: exportScope) { scope in
                exportScope = scope
                performExport(scope: scope)
            }
        }
#if canImport(UIKit)
        .sheet(isPresented: $shareSheetPresented, onDismiss: {
            shareURL = nil
        }) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            } else {
                Text("Unable to share the training summary right now.")
            }
        }
#endif
        .alert("Export Failed", isPresented: $showShareError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("TrainSafe couldn’t create a PDF to share. Please try again.")
        }
    }

    private func performExport(scope: ExportScope) {
#if canImport(UIKit)
        if let url = generateTrainingPDF(scope: scope) {
            shareURL = url
            shareSheetPresented = true
        } else {
            showShareError = true
        }
#elseif canImport(AppKit)
        if let url = generateTrainingPDF(scope: scope) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            showShareError = true
        }
#endif
    }

    // PDF export
    func generateTrainingPDF(scope: ExportScope = .all) -> URL? {
        exportTrainingPDF(store: store, scope: scope)
    }
}

// MARK: - PDF Export Helper
func exportTrainingPDF(store: DataStore, scope: ExportScope = .all) -> URL? {
    var sections: [String] = []
    let header = "TrainSafe Training Summary\nGenerated on \(Date().formatted(date: .long, time: .shortened))\nScope: \(scope.description)\n"
    sections.append(header)

    let scopedSessions = store.sessions.filter { scope.contains($0.date) }
    if scopedSessions.isEmpty {
        sections.append("Sessions\n• No sessions found for \(scope.description).\n")
    } else {
        var sessionLines = ["Sessions"]
        for s in scopedSessions.sorted(by: { $0.date > $1.date }) {
            let line = "• \(s.date.isoDay()): \(s.sport) — Duration \(s.durationMin)m, RPE \(s.rpe), Load \(sessionLoad(s))\(s.notes.isEmpty ? "" : ". Notes: \(s.notes)")"
            sessionLines.append(line)
        }
        sections.append(sessionLines.joined(separator: "\n") + "\n")
    }

    let scopedCheckins = store.checkins.filter { scope.contains($0.date) }
    if scopedCheckins.isEmpty {
        sections.append("Check-Ins\n• No check-ins recorded for \(scope.description).\n")
    } else {
        var checkinLines = ["Check-Ins"]
        for c in scopedCheckins.sorted(by: { $0.date > $1.date }) {
            let sleepValue = RootView.sleepFormatter.string(from: NSNumber(value: c.sleepHours)) ?? String(format: "%.1f", c.sleepHours)
            let notesText = c.notes.isEmpty ? "" : ". Notes: \(c.notes)"
            let line = "• \(c.date.isoDay()): Soreness \(c.soreness)/10, Fatigue \(c.fatigue)/10, Sleep \(sleepValue)h\(notesText)"
            checkinLines.append(line)
        }
        sections.append(checkinLines.joined(separator: "\n") + "\n")
    }

    let scopedInjuries = store.injuries.filter { scope.contains($0.dateOfInjury) }
    if scopedInjuries.isEmpty {
        sections.append("Injury Reports\n• No injuries logged for \(scope.description).\n")
    } else {
        var injuryLines = ["Injury Reports"]
        for injury in scopedInjuries.sorted(by: { $0.dateOfInjury > $1.dateOfInjury }) {
            let severityValue = Int(injury.severity.rounded())
            let noteText = injury.notes.isEmpty ? "" : " Notes: \(injury.notes)"
            let flags = [
                injury.swelling ? "swelling" : nil,
                injury.weightBearing ? "weight bearing" : nil,
                injury.seenPhysio ? "seen physio" : nil
            ].compactMap { $0 }.joined(separator: ", ")
            let flagsText = flags.isEmpty ? "" : " (\(flags))"
            injuryLines.append("• \(injury.dateOfInjury.isoDay()): \(injury.injuryLocation) — \(injury.mechanism). Severity \(severityValue)/10\(flagsText).\(noteText)")
        }
        sections.append(injuryLines.joined(separator: "\n") + "\n")
    }

    let scopedHeights = store.heights.filter { scope.contains($0.date) }
    if scopedHeights.isEmpty {
        sections.append("Growth\n• No height entries captured for \(scope.description).\n")
    } else {
        var heightLines = ["Growth Entries"]
        for h in scopedHeights.sorted(by: { $0.date > $1.date }) {
            let heightValue = RootView.heightFormatter.string(from: NSNumber(value: h.heightCm)) ?? String(format: "%.1f", h.heightCm)
            heightLines.append("• \(h.date.isoDay()): \(heightValue) cm")
        }
        sections.append(heightLines.joined(separator: "\n") + "\n")
    }

    let content = sections.joined(separator: "\n")
    let filename = "trainsafe_\(Date().isoDay()).pdf"
    let url = FileManager.default.temporaryDirectory.appending(path: filename)

#if canImport(UIKit)
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    do {
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let insetRect = pageRect.insetBy(dx: 24, dy: 24)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.label
            ]
            (content as NSString).draw(in: insetRect, withAttributes: attributes)
        }
        return url
    } catch {
        return nil
    }
#elseif canImport(AppKit)
    let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let attributed = NSAttributedString(string: content, attributes: [
        .font: font,
        .foregroundColor: NSColor.labelColor
    ])
    do {
        let data = try attributed.data(from: NSRange(location: 0, length: attributed.length), documentAttributes: [
            .documentType: NSAttributedString.DocumentType.pdf
        ])
        try data.write(to: url)
        return url
    } catch {
        return nil
    }
#else
    return nil
#endif
}

// MARK: - Export Scope Selector
private enum ExportScopeMode: String, CaseIterable, Identifiable {
    case all = "All Data"
    case preset = "Recent"
    case custom = "Custom"

    var id: String { rawValue }
}

private enum ExportPreset: String, CaseIterable, Identifiable {
    case lastMonth = "Last Month"
    case lastSixMonths = "Last 6 Months"
    case lastYear = "Last Year"

    var id: String { rawValue }

    var scope: ExportScope {
        switch self {
        case .lastMonth: return .lastMonth
        case .lastSixMonths: return .lastSixMonths
        case .lastYear: return .lastYear
        }
    }
}

struct ExportScopeSelector: View {
    @Environment(\.dismiss) private var dismiss
    let onExport: (ExportScope) -> Void

    @State private var mode: ExportScopeMode
    @State private var preset: ExportPreset = .lastMonth
    @State private var startDate: Date
    @State private var endDate: Date

    init(initialScope: ExportScope = .all, onExport: @escaping (ExportScope) -> Void) {
        self.onExport = onExport
        let today = Date()
        switch initialScope {
        case .all:
            _mode = State(initialValue: .all)
            _startDate = State(initialValue: Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today)
            _endDate = State(initialValue: today)
        case .lastMonth:
            _mode = State(initialValue: .preset)
            _preset = State(initialValue: .lastMonth)
            _startDate = State(initialValue: Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today)
            _endDate = State(initialValue: today)
        case .lastSixMonths:
            _mode = State(initialValue: .preset)
            _preset = State(initialValue: .lastSixMonths)
            _startDate = State(initialValue: Calendar.current.date(byAdding: .month, value: -6, to: today) ?? today)
            _endDate = State(initialValue: today)
        case .lastYear:
            _mode = State(initialValue: .preset)
            _preset = State(initialValue: .lastYear)
            _startDate = State(initialValue: Calendar.current.date(byAdding: .year, value: -1, to: today) ?? today)
            _endDate = State(initialValue: today)
        case .range(let start, let end):
            _mode = State(initialValue: .custom)
            _startDate = State(initialValue: start)
            _endDate = State(initialValue: end)
        }
    }

    private var resolvedScope: ExportScope {
        switch mode {
        case .all:
            return .all
        case .preset:
            return preset.scope
        case .custom:
            return .range(start: startDate, end: endDate)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Choose what to export")) {
                    Picker("Scope", selection: $mode) {
                        ForEach(ExportScopeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .all:
                        EmptyView()
                    case .preset:
                        Picker("Range", selection: $preset) {
                            ForEach(ExportPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.inline)
                    case .custom:
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section(footer: Text("Sessions, check-ins, growth, and injuries are included when their dates match this range.")) {
                    Text("Exporting: \(resolvedScope.description)")
                }
            }
            .navigationTitle("Export Range")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        onExport(resolvedScope)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Learn More
struct LearnMoreView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TrainSafeBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        heroCard
                        LearnMoreHighlight(
                            icon: "figure.run.circle.fill",
                            accent: .mint,
                            eyebrow: "Built for young athletes",
                            title: "Track every training spark",
                            message: "Quickly log cricket nets, court time, field runs, and more. TrainSafe turns minutes × RPE into your Daily Load so you can spot the perfect balance between hustle and recovery."
                        )
                        LearnMoreHighlight(
                            icon: "speedometer",
                            accent: .orange,
                            eyebrow: "ACWR decoded",
                            title: "See your training waves",
                            message: "ACWR (Acute:Chronic Workload Ratio) compares the average of the last 7 days to the last 28. Hover around 1.0 for steady progress, and watch for spikes above 1.5 that may signal overload."
                        )
                        LearnMoreHighlight(
                            icon: "ruler",
                            accent: .purple,
                            eyebrow: "Growth stats that matter",
                            title: "Celebrate every centimetre",
                            message: "Log heights in cm or metres to reveal your height velocity zone. TrainSafe compares your entries with PHV guides so you know when growth is low, steady, or surging."
                        )
                        playfulFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Learn More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TrainSafe")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .trainSafeVibrantText()
            Text("Injury protection in the palm of your hands")
                .font(.title2.weight(.semibold))
                .trainSafeVibrantText()
            Text("Built for young athletes to track their training load, celebrate growth, and stay ahead of niggles.")
                .font(.headline)
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x2DB2FF),  // Sky blue
                            Color(hex: 0x38D39F)   // Teal green
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 18)
    }

    private var playfulFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game on!")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .trainSafeVibrantText()
            Text("Tap the tabs below, log today’s grind, and let TrainSafe cheer you on with colourful charts, gentle nudges, and growth milestones.")
                .font(.body)
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            HStack(spacing: 12) {
                TagPill(text: "Load Legend", color: .blue)
                TagPill(text: "Recovery Hero", color: .green)
                TagPill(text: "Growth Guru", color: .pink)
            }
        }
        .trainSafeGlassCard(color: Color.white.opacity(0.9), cornerRadius: 28, padding: 24)
    }
}

private struct LearnMoreHighlight: View {
    let icon: String
    let accent: Color
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.22))
                        .frame(width: 56, height: 56)
                        .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 6)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.caption.smallCaps())
                        .foregroundStyle(accent.opacity(0.9))
                        .shadow(color: accent.opacity(0.4), radius: 3, x: 0, y: 2)
                    Text(title)
                        .font(.title3.weight(.bold))
                        .trainSafeVibrantText()
                }
            }
            Text(message)
                .font(.body)
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            Divider()
                .background(accent.opacity(0.4))
        }
        .trainSafeGlassCard(color: Color.white.opacity(0.9), cornerRadius: 28, padding: 24)
    }
}

private struct TagPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(color)
    }
}

struct TrainSafeFormSection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content
    let color: Color

    init(title: String? = nil, subtitle: String? = nil, color: Color = Color.white, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.black.opacity(0.85))
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Color.black.opacity(0.65))
            }
            content
        }
        .trainSafeGlassCard(color: color)
    }
}

struct TrainSafePageHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @Binding var growthTrackingEnabled: Bool
    @EnvironmentObject var store: DataStore
    @AppStorage("TrainSafe_growthReference") private var growthReferenceRaw = GrowthReference.boy.rawValue
    @State private var showLoadInfo = false
    @State private var showAcwrInfo = false
    @State private var showRiskInfo = false
    @State private var showGrowthInsights = false
    @State private var showGrowthReferencePrompt = false
    @State private var activeAlert: DashboardAlert?

    var dailyMap: [String:Int] { dailyLoadMap(sessions: store.sessions) }
    var lastDate: Date { store.sessions.map { $0.date }.sorted().last ?? .today }
    var acwr: Double { computeACWR(dailyMap: dailyMap, endDate: lastDate) }
    var latestCheckIn: CheckIn? { store.checkins.sorted { $0.date < $1.date }.last }
    private var latestSleepDisplay: String {
        guard let latestCheckIn else { return "No check-in" }
        let value = RootView.sleepFormatter.string(from: NSNumber(value: latestCheckIn.sleepHours)) ?? String(format: "%.1f", latestCheckIn.sleepHours)
        return "Sleep \(value)h"
    }
    private var growthReference: GrowthReference { GrowthReference(rawValue: growthReferenceRaw) ?? .boy }
    private var velocitySamples: [GrowthVelocitySample] {
        guard growthTrackingEnabled else { return [] }
        return growthVelocitySamples(heights: store.heights, reference: growthReference)
    }
    private var latestVelocitySample: GrowthVelocitySample? { velocitySamples.last }
    private var growthBand: GrowthVelocityBand? { latestVelocitySample?.band }
    private var velocityThresholds: (low: Double, moderate: Double) { growthReference.monthlyThresholds }
    private var velocityScale: ClosedRange<Double> {
        guard !velocitySamples.isEmpty else { return 0...1 }
        let values = velocitySamples.map { $0.cmPerMonth }
        let minValue = min(0, values.min() ?? 0)
        let referenceCap = velocityThresholds.moderate + 0.3
        let maxValue = max(referenceCap, (values.max() ?? 0) + 0.1)
        return minValue...maxValue
    }
    var risk: (RiskLevel, String) {
        var result = riskScore(acwr: acwr, growthBand: growthTrackingEnabled ? growthBand : nil)
        if growthTrackingEnabled, let band = growthBand {
            result.1 += " " + band.summary(reference: growthReference)
        }
        return result
    }

    var last30: [Date] { dateRange(Calendar.current.date(byAdding: .day, value: -29, to: .today)!, .today) }

    private var growthStatValue: String {
        guard growthTrackingEnabled else { return "Off" }
        if let band = growthBand {
            return band.title
        }
        return store.heights.count >= 2 ? "Pending" : "Log"
    }

    private var growthStatSubtitle: String {
        guard growthTrackingEnabled else { return "Toggle Growth below" }
        if let sample = latestVelocitySample {
            let value = GrowthFormatting.monthly.string(from: NSNumber(value: sample.cmPerMonth)) ?? String(format: "%.2f", sample.cmPerMonth)
            return "\(value) cm/month"
        }
        return "Add height entries"
    }

    private var dashboardGrowthAnalysisText: String {
        guard growthTrackingEnabled else {
            return "Enable growth tracking to view your growth analysis."
        }

        guard !store.heights.isEmpty else {
            return "Log at least one height entry to see your growth analysis."
        }

        guard let latestSample = latestVelocitySample else {
            return "Add another height entry to compare against your latest measurement."
        }

        let direction = latestSample.changeCm >= 0 ? "grown" : "shrunk"
        let daysDescription = latestSample.daysBetween > 0 ? "over the last \(latestSample.daysBetween) days" : "recently"
        let changeDescription = formattedDashboardChange(for: latestSample.changeCm)
        let monthlyValue = GrowthFormatting.monthly.string(from: NSNumber(value: abs(latestSample.cmPerMonth))) ?? String(format: "%.2f", abs(latestSample.cmPerMonth))
        let yearlyValue = GrowthFormatting.yearly.string(from: NSNumber(value: abs(latestSample.cmPerYear))) ?? String(format: "%.1f", abs(latestSample.cmPerYear))

        var message = "You've \(direction) \(changeDescription) \(daysDescription)."
        message += " \(latestSample.band.summary(reference: growthReference))"
        message += " That's about \(monthlyValue) cm/month (≈\(yearlyValue) cm/year)."
        message += " \(latestSample.band.guidance(reference: growthReference))"
        return message
    }

    private func formattedDashboardChange(for centimeters: Double) -> String {
        let absolute = abs(centimeters)
        return String(format: "%.1f cm", absolute)
    }

    var body: some View {
        VStack(spacing: 0) {
            TrainSafePageHeader(title: "Dashboard")
            ScrollView {
                VStack(spacing: 16) {
                    riskSummary
                    if growthTrackingEnabled {
                        growthVelocityTile
                    }
                    loadChart
                    acwrChart
                    recentLists
                    growthToggle
                }
                .padding()
            }
        }

        .alert(item: $activeAlert) { alert in
            switch alert {
            case .growthInfo:
                return Alert(title: Text("Growth Tracking"), message: Text("Recommended for children between 8-15."), dismissButton: .cancel(Text("OK")))
            case .session(let session):
                return Alert(
                    title: Text("Delete this session?"),
                    message: Text("Are you sure you want to delete \(session.sport) from \(session.date.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) {
                        performSessionDeletion(session)
                    },
                    secondaryButton: .cancel()
                )
            case .checkIn(let checkIn):
                return Alert(
                    title: Text("Delete this check-in?"),
                    message: Text("This will remove the check-in from \(checkIn.date.isoDay())."),
                    primaryButton: .destructive(Text("Delete")) {
                        performCheckInDeletion(checkIn)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showRiskInfo) {
            TrafficLightInfoSheet(acwr: acwr, growthEnabled: growthTrackingEnabled, growthBand: growthBand)
        }
        .sheet(isPresented: $showGrowthInsights) {
            GrowthAnalysisSheet(
                analysisText: dashboardGrowthAnalysisText,
                velocitySamples: velocitySamples,
                reference: growthReference,
                velocityScale: velocityScale,
                thresholds: velocityThresholds
            )
        }
        .onChange(of: growthTrackingEnabled) { enabled in
            if enabled {
                showGrowthReferencePrompt = true
            }
        }
        .confirmationDialog("Who are you tracking growth for?", isPresented: $showGrowthReferencePrompt, titleVisibility: .visible) {
            Button("Male") { growthReferenceRaw = GrowthReference.boy.rawValue }
            Button("Female") { growthReferenceRaw = GrowthReference.girl.rawValue }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select a reference so growth velocity is compared to the correct PHV window.")
        }
        .trainSafeScreenBackground(overlay: TrainSafeTilePalette.dashboard)
    }

    var riskSummary: some View {
        HStack(spacing: 12) {
            RiskCard(level: risk.0, message: risk.1, infoAction: { showRiskInfo = true })
                .onTapGesture { showRiskInfo = true }
            StatCard(title: "Latest Check-In", value: latestCheckIn != nil ? "Soreness \(latestCheckIn!.soreness)/10" : "—", subtitle: latestSleepDisplay)
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard, cornerRadius: 28, padding: 16)
    }

    var growthVelocityTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Growth Velocity")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Button {
                    showGrowthInsights = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.black.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Growth velocity info")
            }

            Text(growthStatValue)
                .font(.title3.bold())
                .foregroundColor(.black)
            Text(growthStatSubtitle)
                .font(.caption)
                .foregroundColor(.black.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { if growthTrackingEnabled { showGrowthInsights = true } }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)
    }

    @ViewBuilder
    var loadChart: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Last 30 Days – Daily Load")
                    .font(.headline)
                    .foregroundColor(.black)
                Button {
                    showLoadInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.medium)
                        .foregroundColor(.black.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Daily load info")
                Spacer()
            }

#if canImport(Charts)
            Chart {
                ForEach(last30, id: \.self) { d in
                    let load = dailyMap[d.isoDay()] ?? 0
                    BarMark(x: .value("Date", d), y: .value("Load", load))
                }
            }
            .chartXAxisLabel("Date", alignment: .center)
            .chartYAxisLabel("Load", alignment: .center)
            .frame(height: 220)
#else
            Text("Charts are unavailable on this device.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
#endif
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)
        .alert("Daily Load", isPresented: $showLoadInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Daily load is calculated by multiplying each session's minutes by its RPE. The chart sums all sessions logged on the same day.")
        }
    }

    @ViewBuilder
    var acwrChart: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("ACWR Trend")
                    .font(.headline)
                    .foregroundColor(.black)
                Button {
                    showAcwrInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.medium)
                        .foregroundColor(.black.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ACWR info")
                Spacer()
            }

#if canImport(Charts)
            Chart {
                ForEach(last30, id: \.self) { d in
                    let v = computeACWR(dailyMap: dailyMap, endDate: d)
                    LineMark(x: .value("Date", d), y: .value("ACWR", v))
                }
                RuleMark(y: .value("1.2", 1.2)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                RuleMark(y: .value("1.5", 1.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .chartXAxisLabel("Date", alignment: .center)
            .chartYAxisLabel("ACWR", alignment: .center)
            .frame(height: 220)
#else
            Text("ACWR charts require Apple's Charts framework.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
#endif
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)
        .alert("ACWR", isPresented: $showAcwrInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("ACWR compares the average load of the past 7 days to the average of the past 28 days. A value around 1 means the short-term load matches the longer-term trend, while higher values show a spike.")
        }
    }

    var recentLists: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundColor(.black)
                let sessions = store.sessions.sorted { $0.date > $1.date }
                if sessions.isEmpty { Text("No sessions yet.").foregroundColor(.black.opacity(0.6)) }
                else {
                    ForEach(Array(sessions.prefix(2))) { s in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.sport).font(.subheadline).bold().foregroundColor(.black)
                                Text("\(s.date.isoDay()) • \(s.durationMin)m • RPE \(s.rpe) • Load \(sessionLoad(s))").font(.caption).foregroundColor(.black.opacity(0.65))
                                if !s.notes.isEmpty { Text(s.notes).font(.caption).foregroundColor(.black.opacity(0.75)) }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                activeAlert = .session(s)
                            } label: { Image(systemName: "trash").foregroundColor(.black) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                activeAlert = .session(s)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Divider()
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("Latest Check-Ins")
                    .font(.headline)
                    .foregroundColor(.black)
                    let checkIns = store.checkins.sorted { $0.date > $1.date }
                    if checkIns.isEmpty { Text("No check-ins yet.").foregroundColor(.black.opacity(0.6)) }
                    else {
                        ForEach(Array(checkIns.prefix(2))) { c in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(c.date.isoDay()).font(.subheadline).bold().foregroundColor(.black)
                                    let sleepValue = RootView.sleepFormatter.string(from: NSNumber(value: c.sleepHours)) ?? String(format: "%.1f", c.sleepHours)
                                    Text("Soreness \(c.soreness)/10 • Fatigue \(c.fatigue)/10 • Sleep \(sleepValue)h").font(.caption).foregroundColor(.black.opacity(0.65))
                                    if !c.notes.isEmpty { Text("Notes: \(c.notes)").font(.caption).foregroundColor(.black.opacity(0.75)) }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    activeAlert = .checkIn(c)
                                } label: { Image(systemName: "trash").foregroundColor(.black) }
                        }
                        Divider()
                    }
                }
            }
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)
    }

    var growthToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Toggle(isOn: $growthTrackingEnabled) {
                    Text("Toggle Growth")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .toggleStyle(.switch)
                .accessibilityLabel("Enable growth tracking")

                Button {
                    activeAlert = .growthInfo
                } label: {
                    Label("recommended for children between 8-15", systemImage: "info.circle")
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                        .foregroundColor(.black.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Growth tracking recommendation for children between eight and fifteen")
            }
            Text("Turn this on to reveal the Growth tab and track height changes alongside your training load.")
                .font(.caption)
                .foregroundColor(.black.opacity(0.65))
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard, cornerRadius: 26, padding: 16)
    }

    private func performSessionDeletion(_ session: Session) {
        withAnimation {
            store.sessions.removeAll { $0.id == session.id }
            store.save()
        }
    }

    private func performCheckInDeletion(_ checkIn: CheckIn) {
        withAnimation {
            store.checkins.removeAll { $0.id == checkIn.id }
            store.save()
        }
    }
}

struct RiskCard: View {
    let level: RiskLevel
    let message: String
    var infoAction: (() -> Void)? = nil

    var textColor: Color {
        switch level { case .green: return .green; case .yellow: return .yellow; case .red: return .red }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(textColor.opacity(0.4))
                    .frame(width: 12, height: 12)
                Text("Traffic Light")
                    .font(.caption.weight(.semibold))
                Spacer()
                if let infoAction {
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Traffic light info")
                }
            }
            .foregroundColor(.black.opacity(0.75))

            Text(level.rawValue.capitalized)
                .font(.title3.bold())
                .foregroundColor(.black)
            Text(message)
                .font(.caption)
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(TrainSafeTilePalette.dashboard)
            )
    }

}

enum DashboardAlert: Identifiable {
    case growthInfo
    case session(Session)
    case checkIn(CheckIn)

    var id: String {
        switch self {
        case .growthInfo: return "growthInfo"
        case .session(let session): return "session_\(session.id)"
        case .checkIn(let checkIn): return "checkIn_\(checkIn.id)"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var infoAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.black.opacity(0.6))
                Spacer()
                if let infoAction {
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("More info about \(title)")
                }
            }
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.black)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color.black.opacity(0.65))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(TrainSafeTilePalette.dashboard)
        )
    }
}

struct TrafficLightInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let acwr: Double
    let growthEnabled: Bool
    let growthBand: GrowthVelocityBand?

    private var formattedACWR: String {
        String(format: "%.2f", acwr)
    }

    private var acwrBandDescription: String {
        switch acwr {
        case ..<1.2: return "Balanced: your short-term load matches the past month."
        case 1.2..<1.5: return "Building: load is trending up, so ease into increases."
        default: return "High spike: rapid load jumps can raise injury risk—dial back and recover."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Traffic Light")
                            .font(.largeTitle.bold())
                            .foregroundColor(.black)
                        Text("How we use ACWR to set your signal")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.8))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("What drives the light")
                            .font(.title3.bold())
                            .foregroundColor(.black)
                        Text("• ACWR compares the average load of your last 7 days to the last 28 days. \n• Around 1.0 means your recent load matches your baseline. \n• 1.2–1.5 means you are building—monitor how you feel. \n• Above 1.5 is a spike—consider lighter sessions and extra recovery.")
                            .foregroundColor(.black.opacity(0.8))
                            .font(.body)
                    }
                    .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your current ACWR")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text(formattedACWR)
                            .font(.largeTitle.weight(.semibold))
                            .foregroundColor(.black)
                        Text(acwrBandDescription)
                            .foregroundColor(.black.opacity(0.8))
                            .font(.body)
                    }
                    .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)

                    if growthEnabled, let band = growthBand {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Growth context")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Growth is tracked separately from ACWR, but fast growth can make spikes feel harder. Recent pace: \(band.title).")
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .trainSafeGlassCard(color: TrainSafeTilePalette.dashboard)
                    }
                }
                .padding()
            }
            .navigationTitle("Traffic Light")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.dashboard)
        }
    }
}

// MARK: - Log Session
struct LogSessionView: View {
    @EnvironmentObject var store: DataStore
    @State private var date = Date.today
    @State private var selectedSport: SportOption = .cricket
    @State private var customSport: String = ""
    @State private var durationMinutes = 60
    @State private var rpe = 6
    @State private var notes = ""
    @State private var activeSheet: LogSheet?
    @State private var sessionPendingDeletion: Session?
    @State private var confirmAddSession = false
    @FocusState private var notesFocused: Bool

    private enum LogSheet: Identifiable {
        case calendar, rpe

        var id: String {
            switch self {
            case .calendar: return "calendar"
            case .rpe: return "rpe"
            }
        }
    }

    private var sortedSessions: [Session] {
        store.sessions.sorted { $0.date > $1.date }
    }

    private var recentSessions: [Session] {
        Array(sortedSessions.prefix(2))
    }

    private var sportNameForSaving: String {
        selectedSport.resolvedSport(customName: customSport)
    }

    var body: some View {
        VStack(spacing: 0) {
            TrainSafePageHeader(title: "Log")
            Form {
                TrainSafeFormSection(title: "Log a Training Session for \(store.displayAthleteName)", subtitle: "Add minutes, RPE, and optional notes.", color: TrainSafeTilePalette.log) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Sport", selection: $selectedSport) {
                        ForEach(SportOption.allCases) { option in
                            Text("\(option.symbol) \(option.displayName)").tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSport) { newValue in
                        if newValue != .other {
                            customSport = ""
                        }
                    }
                    if selectedSport == .other {
                        TextField("Enter sport", text: $customSport)
                            .submitLabel(.done)
                            .trainSafeInputFieldBackground()
                    }
                    DurationPickerField(totalMinutes: $durationMinutes)
                    Stepper(value: $rpe, in: 0...10) {
                        HStack {
                            Text("RPE: \(rpe)")
                            Spacer()
                            Button {
                                activeSheet = .rpe
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.blue, .orange, .pink)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("What is RPE?")
                        }
                    }
                    TextField("Notes (optional)", text: $notes)
                        .focused($notesFocused)
                        .submitLabel(.done)
                        .trainSafeInputFieldBackground()
                    Button("Add Session") { confirmAddSession = true }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)

                TrainSafeFormSection(title: "Session History", subtitle: "Use the delete button on each tile. Tap \"View All\" to browse by day.", color: TrainSafeTilePalette.log) {
                    if sortedSessions.isEmpty {
                        Text("No sessions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentSessions) { session in
                            sessionRow(session)
                        }
                        if sortedSessions.count > recentSessions.count {
                            Divider()
                                .background(Color.black.opacity(0.1))
                            Button("View All") {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    activeSheet = .calendar
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .calendar:
                    SessionCalendarView()
                case .rpe:
                    RPEInfoSheet()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .alert(item: $sessionPendingDeletion) { session in
            Alert(
                title: Text("Delete this session?"),
                message: Text("Are you sure you want to delete \(session.sport) from \(session.date.isoDay())?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSession(session)
                },
                secondaryButton: .cancel()
            )
        }
        .confirmationDialog("Add this session?", isPresented: $confirmAddSession, titleVisibility: .visible) {
            Button("Add session") { addSession() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Date: \(date.isoDay())\nSport: \(sportNameForSaving)\nDuration: \(formatDuration(durationMinutes)) • RPE \(rpe)")
        }
        .trainSafeScreenBackground(overlay: TrainSafeTilePalette.log)
    }

    func addSession() {
        let s = Session(date: date, sport: sportNameForSaving, durationMin: durationMinutes, rpe: rpe, notes: notes)
        store.sessions.append(s)
        store.save()
        // reset a bit
        notes = ""
        if selectedSport == .other {
            customSport = ""
        }
        notesFocused = false
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.sport)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Text("\(session.date.isoDay()) • \(session.durationMin)m • RPE \(session.rpe) • Load \(sessionLoad(session))")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.85))
                }
            }
            Spacer(minLength: 12)
            Button {
                sessionPendingDeletion = session
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete session")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.log)
    }

    private func deleteSession(_ session: Session) {
        if let index = store.sessions.firstIndex(where: { $0.id == session.id }) {
            withAnimation {
                store.sessions.remove(at: index)
                store.save()
            }
        }
        sessionPendingDeletion = nil
    }
}

// MARK: - RPE Info
struct RPEInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x8ec5fc), Color(hex: 0xe0c3fc)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What is RPE?")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                        Text("RPE stands for Rate of Perceived Exertion — your personal 0–10 score for how hard the session felt. It blends how heavy the work was with how your body responded (breathing, fatigue, and effort).")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.85))

                        VStack(alignment: .leading, spacing: 14) {
                            infoRow(title: "0–3: Easy Flow", detail: "Light movement or skills work. You could talk comfortably the whole time.", color: Color(hex: 0x9be7ff))
                            infoRow(title: "4–6: Solid Session", detail: "Steady efforts where breathing is up but controlled — most team trainings land here.", color: Color(hex: 0xffe29f))
                            infoRow(title: "7–8: Hard Push", detail: "Intervals, match intensity, or heavy lifts that leave you breathing hard.", color: Color(hex: 0xff8fb1))
                            infoRow(title: "9–10: Max Out", detail: "All-out efforts you can only hold briefly, like sprints to the finish or testing a new PB.", color: Color(hex: 0xb5ffb7))
                        }

                        Text("TrainSafe multiplies your session minutes by RPE to create Daily Load. Keeping most days in the 4–6 range with occasional harder spikes helps balance performance and recovery.")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.85))
                            .padding(.top, 6)
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.black)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(title: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
    }
}

// MARK: - Session Calendar
struct SessionCalendarView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date.today
    @State private var sessionPendingDeletion: Session?

    private let calendar = Calendar.current

    private var sessionsForSelectedDate: [Session] {
        store.sessions
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TrainSafePageHeader(title: "Session Calendar")
                Form {
                    TrainSafeFormSection(title: "Pick a Day", subtitle: "Select a date to see its sessions.", color: TrainSafeTilePalette.log) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.white)
                            .colorScheme(.light)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)

                    TrainSafeFormSection(title: "Sessions on \(selectedDate.isoDay())", subtitle: sessionsForSelectedDate.isEmpty ? "No sessions logged for this day." : "Tap the delete button to remove an entry.", color: TrainSafeTilePalette.log) {
                        if sessionsForSelectedDate.isEmpty {
                            Text("No sessions yet.")
                                .foregroundColor(.black.opacity(0.7))
                        } else {
                            ForEach(sessionsForSelectedDate) { session in
                                sessionTile(session)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(item: $sessionPendingDeletion) { session in
                Alert(
                    title: Text("Delete this session?"),
                    message: Text("Are you sure you want to delete \(session.sport) from \(session.date.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSession(session)
                    },
                    secondaryButton: .cancel()
                )
            }
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.log)
        }
    }

    @ViewBuilder
    private func sessionTile(_ session: Session) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.sport)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Text("\(session.durationMin)m • RPE \(session.rpe) • Load \(sessionLoad(session))")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.85))
                }
            }
            Spacer(minLength: 12)
            Button {
                sessionPendingDeletion = session
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete session")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.log)
    }

    private func deleteSession(_ session: Session) {
        if let index = store.sessions.firstIndex(where: { $0.id == session.id }) {
            withAnimation {
                store.sessions.remove(at: index)
                store.save()
            }
        }
        sessionPendingDeletion = nil
    }
}

struct CheckInCalendarView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date.today
    @State private var checkInPendingDeletion: CheckIn?

    private let calendar = Calendar.current

    private var checkInsForSelectedDate: [CheckIn] {
        store.checkins
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TrainSafePageHeader(title: "Check-In Calendar")
                Form {
                    TrainSafeFormSection(title: "Pick a Day", subtitle: "Select a date to see its check-ins.", color: TrainSafeTilePalette.checkIn) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.white)
                            .colorScheme(.light)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)

                    TrainSafeFormSection(title: "Check-Ins on \(selectedDate.isoDay())", subtitle: checkInsForSelectedDate.isEmpty ? "No check-ins logged for this day." : "Tap the delete button to remove an entry.", color: TrainSafeTilePalette.checkIn) {
                        if checkInsForSelectedDate.isEmpty {
                            Text("No check-ins yet.")
                                .foregroundColor(.black.opacity(0.7))
                        } else {
                            ForEach(checkInsForSelectedDate) { checkIn in
                                checkInTile(checkIn)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(item: $checkInPendingDeletion) { checkIn in
                Alert(
                    title: Text("Delete this check-in?"),
                    message: Text("Are you sure you want to delete the entry from \(checkIn.date.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) { deleteCheckIn(checkIn) },
                    secondaryButton: .cancel()
                )
            }
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.checkIn)
        }
    }

    @ViewBuilder
    private func checkInTile(_ checkIn: CheckIn) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(checkIn.date.isoDay())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                let sleepValue = RootView.sleepFormatter.string(from: NSNumber(value: checkIn.sleepHours)) ?? String(format: "%.1f", checkIn.sleepHours)
                Text("Soreness \(checkIn.soreness)/10 • Fatigue \(checkIn.fatigue)/10 • Sleep \(sleepValue)h")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
                if !checkIn.notes.isEmpty {
                    Text("Notes: \(checkIn.notes)")
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.75))
                }
            }
            Spacer(minLength: 12)
            Button { checkInPendingDeletion = checkIn } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete check-in")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.checkIn)
    }

    private func deleteCheckIn(_ checkIn: CheckIn) {
        if let index = store.checkins.firstIndex(where: { $0.id == checkIn.id }) {
            withAnimation {
                store.checkins.remove(at: index)
                store.save()
            }
        }
        checkInPendingDeletion = nil
    }

}

// MARK: - Duration Picker
struct DurationPickerField: View {
    @Binding var totalMinutes: Int
    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration")
            Button {
                showingPicker = true
            } label: {
                HStack {
                    Text(formatDuration(totalMinutes))
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .trainSafeInputFieldBackground(cornerRadius: 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Duration \(formatDuration(totalMinutes))")
            .sheet(isPresented: $showingPicker) {
                DurationPickerSheet(totalMinutes: $totalMinutes)
            }
        }
    }
}

#if canImport(UIKit)
struct DurationWheelPicker: UIViewRepresentable {
    @Binding var totalMinutes: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.minuteInterval = 1
        picker.countDownDuration = TimeInterval(totalMinutes * 60)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        let desiredDuration = TimeInterval(totalMinutes * 60)
        if uiView.countDownDuration != desiredDuration {
            uiView.countDownDuration = desiredDuration
        }
    }

    class Coordinator: NSObject {
        var parent: DurationWheelPicker

        init(_ parent: DurationWheelPicker) { self.parent = parent }

        @objc func valueChanged(_ sender: UIDatePicker) {
            parent.totalMinutes = max(0, Int(sender.countDownDuration / 60))
        }
    }
}
#endif

struct DurationPickerSheet: View {
    @Binding var totalMinutes: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TrainSafeBackground()
                VStack(spacing: 24) {
#if canImport(UIKit)
                    DurationWheelPicker(totalMinutes: $totalMinutes)
                        .labelsHidden()
#else
                    Stepper("Duration: \(totalMinutes) min", value: $totalMinutes, in: 0...600)
#endif
                    Text(formatDuration(totalMinutes))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Duration")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

}

fileprivate func formatDuration(_ totalMinutes: Int) -> String {
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    switch (hours, minutes) {
    case (0, 0): return "0 min"
    case (_, 0) where hours > 0: return "\(hours) h"
    case (0, _): return "\(minutes) min"
    default: return "\(hours) h \(minutes) min"
    }
}

// MARK: - Check-In
struct CheckInView: View {
    @EnvironmentObject var store: DataStore
    @State private var date = Date.today
    @State private var soreness = 4
    @State private var fatigue = 4
    @State private var sleepHours = 8.0
    @State private var notes = ""
    @State private var showCheckInCalendar = false
    @State private var showInjuryReport = false
    @State private var showInjuryHistory = false
    @State private var activeAlert: CheckInAlert?
    @State private var confirmAddCheckIn = false
    @FocusState private var notesFocused: Bool

    private var sortedCheckIns: [CheckIn] {
        store.checkins.sorted { $0.date > $1.date }
    }

    private var recentCheckIns: [CheckIn] { Array(sortedCheckIns.prefix(2)) }

    private var sleepDisplay: String {
        RootView.sleepFormatter.string(from: NSNumber(value: sleepHours)) ?? String(format: "%.1f", sleepHours)
    }

    private var sortedInjuries: [InjuryReport] {
        store.injuries.sorted { $0.dateOfInjury > $1.dateOfInjury }
    }

    private var recentInjuries: [InjuryReport] { Array(sortedInjuries.prefix(2)) }

    var body: some View {
        VStack(spacing: 0) {
            TrainSafePageHeader(title: "Check-In / Log Injury")
            Form {
                TrainSafeFormSection(title: "Daily Check-In", color: TrainSafeTilePalette.checkIn) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Soreness: \(soreness)/10", value: $soreness, in: 0...10)
                Stepper("Fatigue: \(fatigue)/10", value: $fatigue, in: 0...10)
                Stepper(value: $sleepHours, in: 0...14, step: 0.5) {
                    Text("Sleep: \(sleepDisplay) h")
                }
                TextField("Extra notes (optional)", text: $notes)
                    .focused($notesFocused)
                    .submitLabel(.done)
                    .trainSafeInputFieldBackground()
                Button("Add Check-In") { confirmAddCheckIn = true }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            TrainSafeFormSection(title: "Check-In History", subtitle: "Only the latest two are shown here. Tap View All to browse by date.", color: TrainSafeTilePalette.checkIn) {
                if sortedCheckIns.isEmpty {
                    Text("No check-ins yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentCheckIns) { checkIn in
                        checkInRow(checkIn)
                        if checkIn.id != recentCheckIns.last?.id {
                            Divider().background(Color.black.opacity(0.1))
                        }
                    }
                    if sortedCheckIns.count > recentCheckIns.count {
                        Divider()
                            .background(Color.black.opacity(0.1))
                        Button("View All") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                showCheckInCalendar = true
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            Text("Log Injury")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            TrainSafeFormSection(title: "I got a new injury 🩹", color: TrainSafeTilePalette.checkIn) {
                Button {
                    showInjuryReport = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Log injury details")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Track what happened so you can share it with your coach or physio.")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(TrainSafeTilePalette.checkIn.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 24, trailing: 16))
            .listRowBackground(Color.clear)

            TrainSafeFormSection(title: "Injury History", subtitle: "Latest two injuries are shown. Tap View All for the calendar.", color: TrainSafeTilePalette.checkIn) {
                if sortedInjuries.isEmpty {
                    Text("No injury reports yet.")
                        .foregroundColor(.black.opacity(0.6))
                } else {
                    ForEach(recentInjuries) { injury in
                        injuryRowPreview(injury)
                        if injury.id != recentInjuries.last?.id {
                            Divider().background(Color.black.opacity(0.1))
                        }
                    }
                    if sortedInjuries.count > recentInjuries.count {
                        Divider()
                            .background(Color.black.opacity(0.1))
                        Button("View All") {
                            showInjuryHistory = true
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
            .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .checkIn(let checkIn):
                return Alert(
                    title: Text("Delete this check-in?"),
                    message: Text("Are you sure you want to delete the entry from \(checkIn.date.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) { deleteCheckIn(checkIn) },
                    secondaryButton: .cancel()
                )
            case .injury(let injury):
                return Alert(
                    title: Text("Delete this injury?"),
                    message: Text("Are you sure you want to delete the injury from \(injury.dateOfInjury.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) { deleteInjury(injury) },
                    secondaryButton: .cancel()
                )
            }
        }
        .confirmationDialog("Add this check-in?", isPresented: $confirmAddCheckIn, titleVisibility: .visible) {
            Button("Add check-in") { addCheckIn() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Date: \(date.isoDay())\nSoreness: \(soreness)/10 • Fatigue: \(fatigue)/10\nSleep: \(sleepDisplay)h\(notes.isEmpty ? "" : "\nNotes: \(notes)")")
        }
        .sheet(isPresented: $showInjuryReport) {
            InjuryReportView(isPresented: $showInjuryReport)
                .environmentObject(store)
        }
        .sheet(isPresented: $showCheckInCalendar) {
            CheckInCalendarView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showInjuryHistory) {
            InjuryHistoryView(isPresented: $showInjuryHistory)
                .environmentObject(store)
        }
        .trainSafeScreenBackground(overlay: TrainSafeTilePalette.checkIn)
    }

    func addCheckIn() {
        let c = CheckIn(date: date, soreness: soreness, fatigue: fatigue, sleepHours: sleepHours, notes: notes)
        store.checkins.append(c)
        store.save()
        notes = ""
        notesFocused = false
    }

    @ViewBuilder
    private func checkInRow(_ checkIn: CheckIn) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(checkIn.date.isoDay())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                let sleepValue = RootView.sleepFormatter.string(from: NSNumber(value: checkIn.sleepHours)) ?? String(format: "%.1f", checkIn.sleepHours)
                Text("Soreness \(checkIn.soreness)/10 • Fatigue \(checkIn.fatigue)/10 • Sleep \(sleepValue)h")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
                if !checkIn.notes.isEmpty {
                    Text("Notes: \(checkIn.notes)")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.85))
                }
            }
            Spacer(minLength: 12)
            Button {
                activeAlert = .checkIn(checkIn)
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete check-in")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.checkIn)
    }

    @ViewBuilder
    private func injuryRowPreview(_ injury: InjuryReport) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(injury.dateOfInjury.isoDay())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Text(injury.injuryLocation)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
                Text("Severity: \(Int(injury.severity.rounded()))/10")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.7))
            }
            Spacer(minLength: 12)
            Button {
                activeAlert = .injury(injury)
            } label: {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(.black)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.checkIn)
    }

    private func deleteCheckIn(_ checkIn: CheckIn) {
        if let index = store.checkins.firstIndex(where: { $0.id == checkIn.id }) {
            withAnimation {
                store.checkins.remove(at: index)
                store.save()
            }
        }
        activeAlert = nil
    }

    private func deleteInjury(_ injury: InjuryReport) {
        if let index = store.injuries.firstIndex(where: { $0.id == injury.id }) {
            withAnimation {
                store.injuries.remove(at: index)
                store.save()
            }
        }
        activeAlert = nil
    }
}

struct InjuryReportView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var injuryLocation = ""
    @State private var mechanism = ""
    @State private var dateOfInjury = Date()
    @State private var severity: Double = 5
    @State private var swelling = false
    @State private var weightBearing = true
    @State private var seenPhysio = false
    @State private var notes = ""
    @State private var showSaved = false
    @State private var confirmSaveReport = false
    @FocusState private var focusedField: Field?

    private enum Field { case location, mechanism, notes }

    var body: some View {
        NavigationStack {
            Form {
                injuryDetailsSection
                physioSection
                saveButton
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .navigationTitle("Injury Report")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Save this injury report?", isPresented: $confirmSaveReport, titleVisibility: .visible) {
                Button("Save report") { saveReport() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("""
                Date: \(dateOfInjury.isoDay())
                Severity: \(Int(severity))/10
                Weight bearing: \(weightBearing ? "Yes" : "No")
                """)
            }
            .alert("Saved!", isPresented: $showSaved) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your injury details were stored with your check-ins.")
            }
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.checkIn)
        }
    }

    private var injuryDetailsSection: some View {
        TrainSafeFormSection(title: "New injury details", color: TrainSafeTilePalette.checkIn) {
            VStack(spacing: 12) {
                TextField("Where does it hurt?", text: $injuryLocation)
                    .focused($focusedField, equals: .location)
                    .submitLabel(.next)
                    .trainSafeInputFieldBackground()
                TextField("How did you injure yourself?", text: $mechanism)
                    .focused($focusedField, equals: .mechanism)
                    .submitLabel(.next)
                    .trainSafeInputFieldBackground()
                DatePicker("Date of injury", selection: $dateOfInjury, displayedComponents: .date)
                painSlider
                TextField("Add extra notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .notes)
                    .submitLabel(.done)
                    .trainSafeInputFieldBackground()
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private var painSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("How bad is it right now?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Spacer()
                Text("\(Int(severity))/10")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black)
            }
            HStack {
                Text("🙂")
                Slider(value: $severity, in: 0...10, step: 1)
                    .tint(.orange)
                Text("😖")
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.black.opacity(0.7))
                Text("0 = no pain whatsoever. 10 = worst pain imaginable.")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TrainSafeTilePalette.checkIn.opacity(0.6))
            )
        }
    }

    private var physioSection: some View {
        TrainSafeFormSection(title: "Physiotherapy check-in", color: TrainSafeTilePalette.checkIn) {
            VStack(alignment: .leading, spacing: 14) {
                yesNoRow(title: "Is there swelling?", value: $swelling)
                yesNoRow(title: "Can you put weight on it?", value: $weightBearing)
                yesNoRow(title: "Have you seen a physio?", value: $seenPhysio)
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 24, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private var saveButton: some View {
        Button(action: { confirmSaveReport = true }) {
            Text("Save injury report")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16))
    }

    private func yesNoRow(title: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Picker(title, selection: value) {
                Text("No").tag(false)
                Text("Yes").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }

    private func saveReport() {
        let trimmedLocation = injuryLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMechanism = mechanism.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty, !trimmedMechanism.isEmpty else { return }

        let report = InjuryReport(
            dateOfInjury: dateOfInjury,
            injuryLocation: trimmedLocation,
            mechanism: trimmedMechanism,
            severity: severity,
            swelling: swelling,
            weightBearing: weightBearing,
            seenPhysio: seenPhysio,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.injuries.append(report)
        store.save()
        showSaved = true
    }
}

struct InjuryHistoryView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date.today
    @State private var injuryPendingDeletion: InjuryReport?
    @State private var showShareError = false
    @State private var showExportOptions = false
    @State private var exportScope: ExportScope = .all
#if canImport(UIKit)
    @State private var shareURL: URL?
    @State private var shareSheetPresented = false
#endif

    private var sortedInjuries: [InjuryReport] {
        store.injuries.sorted { $0.dateOfInjury > $1.dateOfInjury }
    }

    private var injuriesForSelectedDate: [InjuryReport] {
        let calendar = Calendar.current
        return sortedInjuries.filter { calendar.isDate($0.dateOfInjury, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            Form {
                TrainSafeFormSection(title: "Pick a Day", subtitle: "Select a date to review injuries.", color: TrainSafeTilePalette.checkIn) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)

                TrainSafeFormSection(title: "Injuries on \(selectedDate.isoDay())", subtitle: injuriesForSelectedDate.isEmpty ? "No injuries logged for this day." : "Tap the trash can to delete entries.", color: TrainSafeTilePalette.checkIn) {
                    if injuriesForSelectedDate.isEmpty {
                        Text("No injury reports yet.")
                            .foregroundColor(.black.opacity(0.6))
                    } else {
                        ForEach(injuriesForSelectedDate) { injury in
                            injuryRow(injury)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)

            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Injury History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
            }
            .alert(item: $injuryPendingDeletion) { injury in
                Alert(
                    title: Text("Delete this injury?"),
                    message: Text("Are you sure you want to delete the injury from \(injury.dateOfInjury.isoDay())?"),
                    primaryButton: .destructive(Text("Delete")) { deleteInjury(injury) },
                    secondaryButton: .cancel()
                )
            }
            .alert("Export Failed", isPresented: $showShareError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("TrainSafe couldn’t create a PDF to share. Please try again.")
            }
        .sheet(isPresented: $showExportOptions) {
            ExportScopeSelector(initialScope: exportScope) { scope in
                exportScope = scope
                performExport(scope: scope)
            }
        }
#if canImport(UIKit)
            .sheet(isPresented: $shareSheetPresented, onDismiss: { shareURL = nil }) {
                if let shareURL {
                    ShareSheet(activityItems: [shareURL])
                } else {
                    Text("Unable to share right now.")
                }
            }
#endif
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.checkIn)
        }
    }

    private var shareButton: some View {
        Button {
            showExportOptions = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func performExport(scope: ExportScope) {
#if canImport(UIKit)
        if let url = exportTrainingPDF(store: store, scope: scope) {
            shareURL = url
            shareSheetPresented = true
        } else {
            showShareError = true
        }
#elseif canImport(AppKit)
        if let url = exportTrainingPDF(store: store, scope: scope) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            showShareError = true
        }
#endif
    }

    private func injuryRow(_ injury: InjuryReport) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(injury.dateOfInjury.isoDay())
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Location: \(injury.injuryLocation)")
                    .foregroundColor(.black)
                Text("Mechanism: \(injury.mechanism)")
                    .foregroundColor(.black.opacity(0.8))
                Text("Severity: \(Int(injury.severity.rounded()))/10")
                    .foregroundColor(.black.opacity(0.8))
                if !injury.notes.isEmpty {
                    Text("Notes: \(injury.notes)")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.8))
                }
                let flags = [
                    injury.swelling ? "Swelling" : nil,
                    injury.weightBearing ? "Weight bearing" : nil,
                    injury.seenPhysio ? "Seen physio" : nil
                ].compactMap { $0 }
                if !flags.isEmpty {
                    Text(flags.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                }
            }
            Spacer()
            Button {
                injuryPendingDeletion = injury
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete injury")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.checkIn)
    }

    private func deleteInjury(_ injury: InjuryReport) {
        if let index = store.injuries.firstIndex(where: { $0.id == injury.id }) {
            withAnimation {
                store.injuries.remove(at: index)
                store.save()
            }
        }
        injuryPendingDeletion = nil
    }
}

// MARK: - Growth
struct GrowthView: View {
    let isEnabled: Bool
    @EnvironmentObject var store: DataStore
    @AppStorage("TrainSafe_growthReference") private var growthReferenceRaw = GrowthReference.boy.rawValue
    @State private var date = Date.today
    @State private var heightInput = "154.0"
    @State private var heightUnit: HeightUnit = .centimeters
    @State private var previousHeightUnit: HeightUnit = .centimeters
    @State private var showGrowthAnalysis = false
    @State private var heightPendingDeletion: HeightEntry?
    @State private var confirmAddHeight = false
    @State private var showAllHeights = false
    @State private var expandedYears: Set<Int> = []
    @FocusState private var heightFieldFocused: Bool

    private var growthReference: GrowthReference { GrowthReference(rawValue: growthReferenceRaw) ?? .boy }
    private var velocitySamples: [GrowthVelocitySample] {
        guard isEnabled else { return [] }
        return growthVelocitySamples(heights: store.heights, reference: growthReference)
    }
    private var latestVelocitySample: GrowthVelocitySample? { velocitySamples.last }
    private var velocityThresholds: (low: Double, moderate: Double) { growthReference.monthlyThresholds }
    private var velocityScale: ClosedRange<Double> {
        guard !velocitySamples.isEmpty else { return 0...1 }
        let values = velocitySamples.map { $0.cmPerMonth }
        let minValue = min(0, values.min() ?? 0)
        let referenceCap = velocityThresholds.moderate + 0.3
        let maxValue = max(referenceCap, (values.max() ?? 0) + 0.1)
        return minValue...maxValue
    }
    var growthAnalysisText: String {
        guard isEnabled else {
            return "Enable growth tracking to view your growth analysis."
        }

        guard !store.heights.isEmpty else {
            return "Log at least one height entry to see your growth analysis."
        }

        guard let latestSample = latestVelocitySample else {
            return "Add another height entry to compare against your latest measurement."
        }

        let changeDescription = formattedChange(for: latestSample.changeCm, unit: heightUnit)
        let direction = latestSample.changeCm >= 0 ? "grown" : "shrunk"
        let daysDescription = latestSample.daysBetween > 0 ? "over the last \(latestSample.daysBetween) days" : "recently"
        let monthlyValue = GrowthFormatting.monthly.string(from: NSNumber(value: abs(latestSample.cmPerMonth))) ?? String(format: "%.2f", abs(latestSample.cmPerMonth))
        let yearlyValue = GrowthFormatting.yearly.string(from: NSNumber(value: abs(latestSample.cmPerYear))) ?? String(format: "%.1f", abs(latestSample.cmPerYear))

        var message = "You've \(direction) \(changeDescription) \(daysDescription)."
        message += " \(latestSample.band.summary(reference: growthReference))"
        message += " That's about \(monthlyValue) cm/month (≈\(yearlyValue) cm/year)."
        message += " \(latestSample.band.guidance(reference: growthReference))"
        return message
    }

    private var sortedHeightEntries: [HeightEntry] {
        store.heights.sorted { $0.date > $1.date }
    }

    private var recentHeightEntries: [HeightEntry] { Array(sortedHeightEntries.prefix(2)) }

    private var heightEntriesByYear: [(year: Int, entries: [HeightEntry])] {
        let grouped = Dictionary(grouping: sortedHeightEntries) { Calendar.current.component(.year, from: $0.date) }
        return grouped.keys.sorted(by: >).map { year in
            (year, grouped[year]?.sorted { $0.date > $1.date } ?? [])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TrainSafePageHeader(title: "Growth")
            Form {
            if isEnabled {
                TrainSafeFormSection(title: "Growth Tracker", color: TrainSafeTilePalette.growth) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack(spacing: 8) {
                        Text("Height:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                        TextField("Enter value", text: $heightInput)
                            .keyboardType(.decimalPad)
                            .focused($heightFieldFocused)
                            .trainSafeInputFieldBackground(cornerRadius: 12)
                        Picker("Unit", selection: $heightUnit) {
                            ForEach(HeightUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .controlSize(.mini)
                        .frame(maxWidth: 110)
                        .onChange(of: heightUnit) { newValue in
                            convertHeightInput(from: previousHeightUnit, to: newValue)
                            previousHeightUnit = newValue
                        }
                    }
                    Button("Add Height") { confirmAddHeight = true }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reference focus")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.75))
                        Picker("Growth reference", selection: $growthReferenceRaw) {
                            ForEach(GrowthReference.allCases) { reference in
                                Text("\(reference.displayName) • \(reference.ageRangeDescription)").tag(reference.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("TrainSafe compares you to \(growthReference.displayName.lowercased()) \(growthReference.ageRangeDescription) PHV trends.")
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)

                TrainSafeFormSection(title: "Height Entries", subtitle: "Latest two are shown here. View All to browse by year.", color: TrainSafeTilePalette.growth) {
                    if sortedHeightEntries.isEmpty {
                        Text("No height entries yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        if showAllHeights {
                            ForEach(heightEntriesByYear, id: \.year) { yearGroup in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { expandedYears.contains(yearGroup.year) },
                                        set: { isExpanded in
                                            if isExpanded { expandedYears.insert(yearGroup.year) }
                                            else { expandedYears.remove(yearGroup.year) }
                                        }
                                    ),
                                    content: {
                                        VStack(spacing: 12) {
                                            ForEach(yearGroup.entries) { entry in
                                                heightRow(entry)
                                                if entry.id != yearGroup.entries.last?.id {
                                                    Divider()
                                                        .background(Color.black.opacity(0.08))
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                    },
                                    label: {
                                        Text("\(yearGroup.year)")
                                            .font(.headline.weight(.semibold))
                                            .foregroundColor(.black)
                                    }
                                )
                                if yearGroup.year != heightEntriesByYear.last?.year {
                                    Divider()
                                        .background(Color.black.opacity(0.12))
                                }
                            }
                        } else {
                            ForEach(recentHeightEntries) { entry in
                                heightRow(entry)
                                if entry.id != recentHeightEntries.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.15))
                                }
                            }
                        }

                        if sortedHeightEntries.count > recentHeightEntries.count {
                            Divider()
                                .background(Color.black.opacity(0.1))
                            Button(showAllHeights ? "Hide All" : "View All") {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    showAllHeights.toggle()
                                    if showAllHeights, let firstYear = heightEntriesByYear.first?.year {
                                        expandedYears = [firstYear]
                                    } else {
                                        expandedYears.removeAll()
                                    }
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)

                TrainSafeFormSection(title: "Growth Analysis", color: TrainSafeTilePalette.growth) {
                    Button {
                        showGrowthAnalysis = true
                    } label: {
                        Label("View Growth Insights", systemImage: "chart.bar.doc.horizontal")
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            } else {
                TrainSafeFormSection(title: "Growth Tracker", subtitle: "Use the Toggle Growth switch on the dashboard to add height entries and unlock growth insights.", color: TrainSafeTilePalette.growth) {
                    Text("Growth tracking is off right now.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { heightFieldFocused = false }
            }
        }
        .alert(item: $heightPendingDeletion) { entry in
            Alert(
                title: Text("Delete this height entry?"),
                message: Text("Are you sure you want to delete the measurement from \(entry.date.isoDay())?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteHeightEntry(entry)
                },
                secondaryButton: .cancel()
            )
        }
        .confirmationDialog("Add this height entry?", isPresented: $confirmAddHeight, titleVisibility: .visible) {
            Button("Add height") { addHeight() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Date: \(date.isoDay())\nHeight: \(heightInput) \(heightUnit.displayName)")
        }
        .sheet(isPresented: $showGrowthAnalysis) {
            GrowthAnalysisSheet(
                analysisText: growthAnalysisText,
                velocitySamples: velocitySamples,
                reference: growthReference,
                velocityScale: velocityScale,
                thresholds: velocityThresholds
            )
        }
        .onAppear {
            previousHeightUnit = heightUnit
            if let value = Double(heightInput) {
                let centimeters = heightUnit.convertToCentimeters(value)
                heightInput = formattedHeight(for: centimeters, unit: heightUnit)
            }
        }
        .onChange(of: isEnabled) { enabled in
            if !enabled {
                showGrowthAnalysis = false
                heightFieldFocused = false
                showAllHeights = false
                expandedYears.removeAll()
            }
        }
        .trainSafeScreenBackground(overlay: TrainSafeTilePalette.growth)
    }

    func addHeight() {
        guard isEnabled else { return }
        guard let enteredValue = Double(heightInput) else { return }
        let heightCm = heightUnit.convertToCentimeters(enteredValue)
        let h = HeightEntry(date: date, heightCm: heightCm)
        store.heights.append(h)
        store.save()
        heightInput = formattedHeight(for: heightCm, unit: heightUnit)
        heightFieldFocused = false
    }

    @ViewBuilder
    private func heightRow(_ entry: HeightEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.isoDay())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Text("\(formattedHeight(for: entry.heightCm, unit: heightUnit)) \(heightUnit.displayName)")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.75))
            }
            Spacer(minLength: 12)
            Button {
                heightPendingDeletion = entry
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete height entry")
        }
        .trainSafeEntryTile(color: TrainSafeTilePalette.growth)
    }

    private func deleteHeightEntry(_ entry: HeightEntry) {
        if let index = store.heights.firstIndex(where: { $0.id == entry.id }) {
            withAnimation {
                store.heights.remove(at: index)
                store.save()
            }
        }
        heightPendingDeletion = nil
    }

    private func convertHeightInput(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        guard let currentValue = Double(heightInput) else { return }
        let centimeters = oldUnit.convertToCentimeters(currentValue)
        heightInput = formattedHeight(for: centimeters, unit: newUnit)
    }

    private func formattedHeight(for centimeters: Double, unit: HeightUnit) -> String {
        let value = unit.convertFromCentimeters(centimeters)
        switch unit {
        case .centimeters:
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", value)
                : String(format: "%.1f", value)
        case .meters:
            return String(format: "%.2f", value)
        }
    }

    private func formattedChange(for centimeters: Double, unit: HeightUnit) -> String {
        let converted = unit.convertFromCentimeters(abs(centimeters))
        switch unit {
        case .centimeters:
            return String(format: "%.1f %@", converted, unit.displayName)
        case .meters:
            return String(format: "%.2f %@", converted, unit.displayName)
        }
    }
}

private struct GrowthVelocityLegend: View {
    let reference: GrowthReference

    private var thresholds: (low: Double, moderate: Double) {
        reference.monthlyThresholds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(reference.displayName) velocity guide")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
            ForEach(GrowthVelocityBand.allCases) { band in
                HStack(spacing: 12) {
                    Circle()
                        .fill(band.color.opacity(0.25))
                        .frame(width: 16, height: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(band.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.black)
                        Text(rangeDescription(for: band))
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
            Text("Guide is based on 50th percentile PHV ranges for \(reference.displayName.lowercased()).")
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
        }
        .padding(.top, 8)
    }

    private func rangeDescription(for band: GrowthVelocityBand) -> String {
        let lowText = String(format: "%.2f", thresholds.low)
        let highText = String(format: "%.2f", thresholds.moderate)
        switch band {
            case .low:
                return "Less than \(lowText) cm/month"
            case .moderate:
                return "Between \(lowText)–\(highText) cm/month"
            case .high:
                return "Above \(highText) cm/month"
        }
    }
}

private struct GrowthAnalysisSheet: View {
    let analysisText: String
    let velocitySamples: [GrowthVelocitySample]
    let reference: GrowthReference
    let velocityScale: ClosedRange<Double>
    let thresholds: (low: Double, moderate: Double)

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Growth Insights")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.black)

                    Text(analysisText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .trainSafeEntryTile(color: TrainSafeTilePalette.growth, cornerRadius: 24)

                    if velocitySamples.isEmpty {
                        Text("Add at least two height entries to unlock your height velocity chart.")
                            .font(.callout)
                            .foregroundColor(.black.opacity(0.75))
                            .trainSafeEntryTile(color: TrainSafeTilePalette.growth, cornerRadius: 24)
                    } else {
                        velocitySection
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .trainSafeScreenBackground(overlay: TrainSafeTilePalette.growth)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.headline)
                }
            }
        }
    }

    private var velocitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Height velocity zones")
                .font(.title3.weight(.semibold))
                .foregroundColor(.black)
#if canImport(Charts)
            Chart {
                ForEach(velocitySamples) { sample in
                    BarMark(
                        x: .value("Period End", sample.periodEnd),
                        y: .value("cm/month", sample.cmPerMonth)
                    )
                    .foregroundStyle(sample.band.color.gradient)
                    .cornerRadius(10)
                    .annotation(position: .top, alignment: .center) {
                        Text(sample.band.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.black)
                    }
                }
                RuleMark(y: .value("Low cap", thresholds.low))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Moderate zone starts")
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.7))
                    }
                RuleMark(y: .value("High cap", thresholds.moderate))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .annotation(position: .top, alignment: .leading) {
                        Text("High zone starts")
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.7))
                    }
            }
            .chartYScale(domain: velocityScale)
            .chartXAxisLabel("Period end", alignment: .center)
            .chartYAxisLabel("cm/month")
            .frame(height: 260)
#else
            Text("Charts are unavailable on this device.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
#endif

            GrowthVelocityLegend(reference: reference)
        }
        .trainSafeGlassCard(color: TrainSafeTilePalette.growth, cornerRadius: 28, padding: 20)
    }
}

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
#endif

enum HeightUnit: String, CaseIterable, Identifiable {
    case centimeters
    case meters

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .centimeters: return "cm"
        case .meters: return "m"
        }
    }

    func convertToCentimeters(_ value: Double) -> Double {
        switch self {
        case .centimeters: return value
        case .meters: return value * 100
        }
    }

    func convertFromCentimeters(_ centimeters: Double) -> Double {
        switch self {
        case .centimeters: return centimeters
        case .meters: return centimeters / 100
        }
    }
}
