import SwiftUI
import Charts
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
    var pain: Int
    var soreness: Int
    var fatigue: Int
    var sleepHours: Double
    var mood: Int
    var redFlags: String = ""
}

struct HeightEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var date: Date
    var heightCm: Double
}

enum SportOption: String, CaseIterable, Identifiable {
    case cricket
    case running
    case tennis
    case basketball
    case soccer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cricket: return "Cricket"
        case .running: return "Running"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        }
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

/// Detect growth spurt: >1.5 cm in ~30 days (illustrative)
func growthSpurtRisk(heights: [HeightEntry]) -> Bool {
    let sorted = heights.sorted { $0.date < $1.date }
    guard sorted.count >= 2 else { return false }
    let last = sorted.last!
    for i in stride(from: sorted.count - 2, through: 0, by: -1) {
        let prev = sorted[i]
        let days = Calendar.current.dateComponents([.day], from: prev.date, to: last.date).day ?? 0
        if days >= 25 && days <= 40 {
            let delta = last.heightCm - prev.heightCm
            return delta >= 1.5
        }
    }
    return false
}

enum RiskLevel: String { case green, amber, red }

func riskScore(acwr: Double, checkIn: CheckIn?, growthSpurt: Bool) -> (RiskLevel, String) {
    var score = 0
    if acwr >= 1.5 { score += 2 }
    else if acwr >= 1.2 { score += 1 }

    if let c = checkIn {
        if c.pain >= 5 || c.soreness >= 6 { score += 2 }
        else if c.pain >= 3 || c.soreness >= 4 { score += 1 }
        if c.fatigue >= 6 { score += 1 }
    }
    if growthSpurt { score += 1 }

    if score >= 3 { return (.red, "High overload risk – reduce load & prioritise recovery.") }
    if score == 2 { return (.amber, "Moderate risk – monitor symptoms, consider lighter sessions.") }
    return (.green, "Load looks OK – continue as planned.")
}

// MARK: - Persistence
final class DataStore: ObservableObject {
    @Published var athleteName: String = "Alex"
    @Published var sessions: [Session] = []
    @Published var checkins: [CheckIn] = []
    @Published var heights: [HeightEntry] = []

    private let K_sessions = "loadsafekids_sessions"
    private let K_checkins = "loadsafekids_checkins"
    private let K_heights = "loadsafekids_heights"
    private let K_profile = "loadsafekids_profile"

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
    }

    func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(sessions) { UserDefaults.standard.set(d, forKey: K_sessions) }
        if let d = try? enc.encode(checkins) { UserDefaults.standard.set(d, forKey: K_checkins) }
        if let d = try? enc.encode(heights) { UserDefaults.standard.set(d, forKey: K_heights) }
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
            CheckIn(date: today, pain: 3, soreness: 4, fatigue: 4, sleepHours: 8, mood: 4)
        ]
        heights = [
            HeightEntry(date: Calendar.current.date(byAdding: .day, value: -32, to: today)!, heightCm: 152),
            HeightEntry(date: today, heightCm: 154)
        ]
        save()
    }
}

// MARK: - App Entry
@main
struct TrainSafeApp: App {
    @StateObject private var store = DataStore()
    @AppStorage("TrainSafe_hasLoggedIn") private var hasCompletedLogin = false
    var body: some Scene {
        WindowGroup {
            if hasCompletedLogin {
                RootView(onLogout: {
                    hasCompletedLogin = false
                })
                .environmentObject(store)
            } else {
                TitleScreen {
                    hasCompletedLogin = true
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
    @State private var exportURL: URL? = nil
    @State private var showLogoutConfirmation = false
    @State private var showLearnMore = false

    private static let sleepFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let heightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    private var displayAthleteName: String {
        let trimmed = store.athleteName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Athlete" : trimmed
    }

    var body: some View {
        NavigationStack {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "gauge.medium") }
                LogSessionView()
                    .tabItem { Label("Log", systemImage: "square.and.pencil") }
                CheckInView()
                    .tabItem { Label("Check-In", systemImage: "checkmark.circle") }
                GrowthView()
                    .tabItem { Label("Growth", systemImage: "ruler") }
            }
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
                    .accessibilityLabel("Profile for \(displayAthleteName)")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showLearnMore = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Learn more about TrainSafe")

                    if let url = exportURL {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    } else {
                        Button { exportURL = exportTrainingPDF() } label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
        }
        .confirmationDialog("Sign out of \(displayAthleteName)?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out \(displayAthleteName)", role: .destructive) {
                showLogoutConfirmation = false
                onLogout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\(displayAthleteName) will be logged out and returned to the login screen. Your saved training data will remain on this device.")
        }
        .sheet(isPresented: $showLearnMore) {
            LearnMoreView()
        }
    }

    // PDF export
    func exportTrainingPDF() -> URL? {
        var sections: [String] = []
        let header = "TrainSafe Training Summary\nGenerated on \(Date().formatted(date: .long, time: .shortened))\n"
        sections.append(header)

        if store.sessions.isEmpty {
            sections.append("Sessions\n• No sessions logged yet.\n")
        } else {
            var sessionLines = ["Sessions"]
            for s in store.sessions.sorted(by: { $0.date > $1.date }) {
                let line = "• \(s.date.isoDay()): \(s.sport) — Duration \(s.durationMin)m, RPE \(s.rpe), Load \(sessionLoad(s))\(s.notes.isEmpty ? "" : ". Notes: \(s.notes)")"
                sessionLines.append(line)
            }
            sections.append(sessionLines.joined(separator: "\n") + "\n")
        }

        if store.checkins.isEmpty {
            sections.append("Check-Ins\n• No check-ins recorded.\n")
        } else {
            var checkinLines = ["Check-Ins"]
            for c in store.checkins.sorted(by: { $0.date > $1.date }) {
                let sleepValue = RootView.sleepFormatter.string(from: NSNumber(value: c.sleepHours)) ?? String(format: "%.1f", c.sleepHours)
                let line = "• \(c.date.isoDay()): Pain \(c.pain)/10, Soreness \(c.soreness)/10, Fatigue \(c.fatigue)/10, Sleep \(sleepValue)h, Mood \(c.mood)/5\(c.redFlags.isEmpty ? "" : ". Red Flags: \(c.redFlags)")"
                checkinLines.append(line)
            }
            sections.append(checkinLines.joined(separator: "\n") + "\n")
        }

        if store.heights.isEmpty {
            sections.append("Growth\n• No height entries captured yet.\n")
        } else {
            var heightLines = ["Growth Entries"]
            for h in store.heights.sorted(by: { $0.date > $1.date }) {
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
}

// MARK: - Learn More
struct LearnMoreView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                        message: "Log heights in cm or metres to reveal growth spurts. TrainSafe flags leaps greater than 1.5 cm in about a month so you can adjust training and stay nimble as you grow."
                    )
                    playfulFooter
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.35), Color(.systemTeal).opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
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
                .foregroundStyle(.white)
            Text("Injury protection in the palm of your hands")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
            Text("Built for young athletes to track their training load, celebrate growth, and stay ahead of niggles.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemPurple), Color(.systemPink)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color(.black).opacity(0.18), radius: 20, x: 0, y: 18)
    }

    private var playfulFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game on!")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(.label))
            Text("Tap the tabs below, log today’s grind, and let TrainSafe cheer you on with colourful charts, gentle nudges, and growth milestones.")
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
            HStack(spacing: 12) {
                TagPill(text: "Load Legend", color: .blue)
                TagPill(text: "Recovery Hero", color: .green)
                TagPill(text: "Growth Guru", color: .pink)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
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
                        .fill(accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.caption.smallCaps())
                        .foregroundStyle(accent)
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color(.label))
                }
            }
            Text(message)
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
            Divider()
                .background(accent.opacity(0.5))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.15), radius: 8, x: 0, y: 8)
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

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var showLoadInfo = false
    @State private var showAcwrInfo = false

    var dailyMap: [String:Int] { dailyLoadMap(sessions: store.sessions) }
    var lastDate: Date { store.sessions.map { $0.date }.sorted().last ?? .today }
    var acwr: Double { computeACWR(dailyMap: dailyMap, endDate: lastDate) }
    var latestCheckIn: CheckIn? { store.checkins.sorted { $0.date < $1.date }.last }
    var spurt: Bool { growthSpurtRisk(heights: store.heights) }
    var risk: (RiskLevel, String) { riskScore(acwr: acwr, checkIn: latestCheckIn, growthSpurt: spurt) }

    var last30: [Date] { dateRange(Calendar.current.date(byAdding: .day, value: -29, to: .today)!, .today) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                riskSummary
                loadChart
                acwrChart
                recentLists
            }.padding()
        }
    }

    var riskSummary: some View {
        HStack(spacing: 12) {
            RiskCard(level: risk.0, message: risk.1)
            StatCard(title: "ACWR", value: String(format: "%.2f", acwr), subtitle: "7-day / 28-day")
            StatCard(title: "Latest Check-In", value: latestCheckIn != nil ? "Pain \(latestCheckIn!.pain)/10" : "—", subtitle: latestCheckIn != nil ? "Sleep \(latestCheckIn!.sleepHours)h" : "No check-in")
            StatCard(title: "Growth Spurt", value: spurt ? "Detected" : "No", subtitle: "Monthly change")
        }
    }

    var loadChart: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Last 30 Days – Daily Load").font(.headline)
                Button {
                    showLoadInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Daily load info")
                Spacer()
            }
            Chart {
                ForEach(last30, id: \.self) { d in
                    BarMark(x: .value("Date", d), y: .value("Load", dailyMap[d.isoDay()] ?? 0))
                }
            }
            .frame(height: 220)
        }
        .alert("Daily Load", isPresented: $showLoadInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Daily load is calculated by multiplying each session's minutes by its RPE. The chart sums all sessions logged on the same day.")
        }
    }

    var acwrChart: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("ACWR Trend").font(.headline)
                Button {
                    showAcwrInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ACWR info")
                Spacer()
            }
            Chart {
                ForEach(last30, id: \.self) { d in
                    let v = computeACWR(dailyMap: dailyMap, endDate: d)
                    LineMark(x: .value("Date", d), y: .value("ACWR", v))
                }
                RuleMark(y: .value("1.2", 1.2)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                RuleMark(y: .value("1.5", 1.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .frame(height: 220)
        }
        .alert("ACWR", isPresented: $showAcwrInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("ACWR compares the average load of the past 7 days to the average of the past 28 days. A value around 1 means the short-term load matches the longer-term trend, while higher values show a spike.")
        }
    }

    var recentLists: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Recent Sessions").font(.headline)
                if store.sessions.isEmpty { Text("No sessions yet.").foregroundStyle(.secondary) }
                else {
                    ForEach(store.sessions.sorted { $0.date > $1.date }.prefix(6)) { s in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.sport).font(.subheadline).bold()
                                Text("\(s.date.isoDay()) • \(s.durationMin)m • RPE \(s.rpe) • Load \(sessionLoad(s))").font(.caption).foregroundStyle(.secondary)
                                if !s.notes.isEmpty { Text(s.notes).font(.caption) }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                withAnimation { store.sessions.removeAll { $0.id == s.id }; store.save() }
                            } label: { Image(systemName: "trash") }
                        }
                        Divider()
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("Latest Check-Ins").font(.headline)
                if store.checkins.isEmpty { Text("No check-ins yet.").foregroundStyle(.secondary) }
                else {
                    ForEach(store.checkins.sorted { $0.date > $1.date }.prefix(6)) { c in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(c.date.isoDay()).font(.subheadline).bold()
                                Text("Pain \(c.pain)/10 • Soreness \(c.soreness)/10 • Fatigue \(c.fatigue)/10 • Sleep \(Int(c.sleepHours))h • Mood \(c.mood)/5").font(.caption).foregroundStyle(.secondary)
                                if !c.redFlags.isEmpty { Text("Red flags: \(c.redFlags)").font(.caption) }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                withAnimation { store.checkins.removeAll { $0.id == c.id }; store.save() }
                            } label: { Image(systemName: "trash") }
                        }
                        Divider()
                    }
                }
            }
        }
    }
}

struct RiskCard: View {
    let level: RiskLevel
    let message: String
    var color: Color {
        switch level { case .green: return .green.opacity(0.2); case .amber: return .yellow.opacity(0.25); case .red: return .red.opacity(0.2) }
    }
    var textColor: Color {
        switch level { case .green: return .green; case .amber: return .orange; case .red: return .red }
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text("Traffic Light").font(.caption).foregroundStyle(.secondary)
            Text(level.rawValue.capitalized).font(.title3).bold().foregroundStyle(textColor)
            Text(message).font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).stroke(textColor.opacity(0.4)).background(RoundedRectangle(cornerRadius: 16).fill(color)))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3).bold()
            Text(subtitle).font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Log Session
struct LogSessionView: View {
    @EnvironmentObject var store: DataStore
    @State private var date = Date.today
    @State private var selectedSport: SportOption = .cricket
    @State private var durationMinutes = 60
    @State private var rpe = 6
    @State private var notes = ""
    @FocusState private var notesFocused: Bool

    var body: some View {
        Form {
            Section("Log a Training Session for \(store.athleteName)") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Sport", selection: $selectedSport) {
                    ForEach(SportOption.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                DurationPickerField(totalMinutes: $durationMinutes)
                Stepper("RPE: \(rpe)", value: $rpe, in: 0...10)
                TextField("Notes (optional)", text: $notes)
                    .focused($notesFocused)
                    .submitLabel(.done)
                Button("Add Session") { addSession() }
            }
            Section("All Sessions") {
                if store.sessions.isEmpty { Text("No sessions yet.").foregroundStyle(.secondary) }
                ForEach(store.sessions.sorted { $0.date > $1.date }) { s in
                    VStack(alignment: .leading) {
                        Text(s.sport).bold()
                        Text("\(s.date.isoDay()) • \(s.durationMin)m • RPE \(s.rpe) • Load \(sessionLoad(s))").font(.caption).foregroundStyle(.secondary)
                        if !s.notes.isEmpty { Text(s.notes).font(.caption) }
                    }
                }
                .onDelete { idx in store.sessions.remove(atOffsets: idx); store.save() }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
    }

    func addSession() {
        let s = Session(date: date, sport: selectedSport.displayName, durationMin: durationMinutes, rpe: rpe, notes: notes)
        store.sessions.append(s)
        store.save()
        // reset a bit
        notes = ""
        notesFocused = false
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
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
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
    @State private var pain = 3
    @State private var soreness = 4
    @State private var fatigue = 4
    @State private var sleepHours = 8.0
    @State private var mood = 4
    @State private var redFlags = ""
    @FocusState private var redFlagsFocused: Bool

    var body: some View {
        Form {
            Section("Daily Check-In") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Pain: \(pain)/10", value: $pain, in: 0...10)
                Stepper("Soreness: \(soreness)/10", value: $soreness, in: 0...10)
                Stepper("Fatigue: \(fatigue)/10", value: $fatigue, in: 0...10)
                Stepper("Sleep: \(Int(sleepHours)) h", value: $sleepHours, in: 0...14, step: 1)
                Stepper("Mood: \(mood)/5", value: $mood, in: 1...5)
                TextField("Red flags (optional)", text: $redFlags)
                    .focused($redFlagsFocused)
                    .submitLabel(.done)
                Button("Add Check-In") { addCheckIn() }
            }
            Section("All Check-Ins") {
                if store.checkins.isEmpty { Text("No check-ins yet.").foregroundStyle(.secondary) }
                ForEach(store.checkins.sorted { $0.date > $1.date }) { c in
                    VStack(alignment: .leading) {
                        Text(c.date.isoDay()).bold()
                        Text("Pain \(c.pain)/10 • Soreness \(c.soreness)/10 • Fatigue \(c.fatigue)/10 • Sleep \(Int(c.sleepHours))h • Mood \(c.mood)/5").font(.caption).foregroundStyle(.secondary)
                        if !c.redFlags.isEmpty { Text("Red flags: \(c.redFlags)").font(.caption) }
                    }
                }
                .onDelete { idx in store.checkins.remove(atOffsets: idx); store.save() }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { redFlagsFocused = false }
            }
        }
    }

    func addCheckIn() {
        let c = CheckIn(date: date, pain: pain, soreness: soreness, fatigue: fatigue, sleepHours: sleepHours, mood: mood, redFlags: redFlags)
        store.checkins.append(c)
        store.save()
        redFlags = ""
        redFlagsFocused = false
    }
}

// MARK: - Growth
struct GrowthView: View {
    @EnvironmentObject var store: DataStore
    @State private var date = Date.today
    @State private var heightInput = "154.0"
    @State private var heightUnit: HeightUnit = .centimeters
    @State private var previousHeightUnit: HeightUnit = .centimeters
    @State private var showGrowthAnalysis = false
    @FocusState private var heightFieldFocused: Bool

    var spurt: Bool { growthSpurtRisk(heights: store.heights) }
    var growthAnalysisText: String {
        let sorted = store.heights.sorted { $0.date < $1.date }
        guard let latest = sorted.last else {
            return "Log at least one height entry to see your growth analysis."
        }
        guard let comparison = comparisonEntry(against: latest, in: sorted) else {
            return "Add another height entry to compare against \(latest.date.isoDay())."
        }

        let changeCm = latest.heightCm - comparison.heightCm
        let daysBetween = Calendar.current.dateComponents([.day], from: comparison.date, to: latest.date).day ?? 0
        let daysDescription = daysBetween > 0 ? "in the last \(daysBetween) days" : "since the previous entry"

        if changeCm == 0 {
            return "Your height has not changed \(daysDescription). This is below the 1.5 cm growth spurt threshold."
        }

        let formattedChange = formattedChange(for: changeCm, unit: heightUnit)
        let direction = changeCm > 0 ? "grown" : "shrunk"

        if spurt {
            return "Growth spurt detected! You've \(direction) \(formattedChange) \(daysDescription), which exceeds the 1.5 cm in about a month guideline."
        } else {
            return "You've \(direction) \(formattedChange) \(daysDescription). This is below the 1.5 cm growth spurt threshold."
        }
    }

    var body: some View {
        Form {
            Section("Growth Tracker") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                HStack(spacing: 8) {
                    Text("Height:")
                    TextField("Enter value", text: $heightInput)
                        .keyboardType(.decimalPad)
                        .focused($heightFieldFocused)
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
                Button("Add Height") { addHeight() }
            }
            Section("Height Over Time") {
                if store.heights.isEmpty { Text("No height entries yet.").foregroundStyle(.secondary) }
                else {
                    Chart(store.heights.sorted { $0.date < $1.date }) { h in
                        LineMark(x: .value("Date", h.date), y: .value("Height", heightUnit.convertFromCentimeters(h.heightCm)))
                        PointMark(x: .value("Date", h.date), y: .value("Height", heightUnit.convertFromCentimeters(h.heightCm)))
                    }
                    .chartYAxisLabel(heightUnit.displayName.uppercased())
                    .frame(height: 240)
                }
            }
            Section("All Entries") {
                ForEach(store.heights.sorted { $0.date > $1.date }) { h in
                    HStack {
                        Text(h.date.isoDay())
                        Spacer()
                        Text("\(formattedHeight(for: h.heightCm, unit: heightUnit)) \(heightUnit.displayName)")
                    }
                }
                .onDelete { idx in store.heights.remove(atOffsets: idx); store.save() }
            }
            Section("Growth Analysis") {
                Button {
                    showGrowthAnalysis = true
                } label: {
                    Label("View Growth Insights", systemImage: "chart.bar.doc.horizontal")
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { heightFieldFocused = false }
            }
        }
        .alert("Growth Analysis", isPresented: $showGrowthAnalysis) {
            Button("Close", role: .cancel) { }
        } message: {
            Text(growthAnalysisText)
        }
        .onAppear {
            previousHeightUnit = heightUnit
            if let value = Double(heightInput) {
                let centimeters = heightUnit.convertToCentimeters(value)
                heightInput = formattedHeight(for: centimeters, unit: heightUnit)
            }
        }
    }

    func addHeight() {
        guard let enteredValue = Double(heightInput) else { return }
        let heightCm = heightUnit.convertToCentimeters(enteredValue)
        let h = HeightEntry(date: date, heightCm: heightCm)
        store.heights.append(h)
        store.save()
        heightInput = formattedHeight(for: heightCm, unit: heightUnit)
        heightFieldFocused = false
    }

    private func convertHeightInput(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        guard let currentValue = Double(heightInput) else { return }
        let centimeters = oldUnit.convertToCentimeters(currentValue)
        heightInput = formattedHeight(for: centimeters, unit: newUnit)
    }

    private func comparisonEntry(against latest: HeightEntry, in entries: [HeightEntry]) -> HeightEntry? {
        let priorEntries = entries.dropLast()
        guard !priorEntries.isEmpty else { return nil }

        let cal = Calendar.current
        if let match = priorEntries.reversed().first(where: { entry in
            guard let days = cal.dateComponents([.day], from: entry.date, to: latest.date).day else { return false }
            return days >= 25 && days <= 40
        }) {
            return match
        }

        return priorEntries.last
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
