import WidgetKit
import SwiftUI

// MARK: - Timeline

struct SoberEntry: TimelineEntry {
    let date: Date
    let days: Int
    let currentStreak: Int
    let progress: Double
    let nextLabel: String
    let remaining: Int
    let moneySaved: Double?
    let recent: [Bool]   // last 91 days, oldest -> newest
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SoberEntry {
        SoberEntry(date: Date(), days: 78, currentStreak: 78, progress: 0.86,
                   nextLabel: "90 days", remaining: 12, moneySaved: 1170,
                   recent: (0..<91).map { _ in Bool.random() })
    }

    func getSnapshot(in context: Context, completion: @escaping (SoberEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SoberEntry>) -> Void) {
        let entry = makeEntry()
        // refresh at the next local midnight so the day count rolls over
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0),
                                        matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry() -> SoberEntry {
        let data = SobrietyData.load()
        let n = data.daysSober
        let m = Milestones.next(after: n)
        let span = Double(m.next - m.prev)
        let progress = span > 0 ? min(1, max(0, Double(n - m.prev) / span)) : 0

        let cal = Calendar.current
        var recent: [Bool] = []
        for i in stride(from: 90, through: 0, by: -1) {
            let day = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: Date()))!
            recent.append(data.isSober(data.key(day)))
        }

        return SoberEntry(date: Date(), days: n, currentStreak: data.currentStreak,
                          progress: progress, nextLabel: Milestones.label(m.next),
                          remaining: m.next - n, moneySaved: data.moneySaved, recent: recent)
    }
}

// MARK: - Views

struct SoberWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SoberEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryInline:   inline
        case .accessoryRectangular: rectangular
        case .systemMedium:      medium
        default:                 small
        }
    }

    // Home-screen small: number + label + next milestone
    private var small: some View {
        ZStack {
            Theme.bg
            VStack(spacing: 2) {
                Text("\(entry.days)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [Theme.level4, Theme.accent], startPoint: .top, endPoint: .bottom))
                Text(entry.days == 1 ? "day sober" : "days sober")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textDim)
                Text("\(entry.remaining) to \(entry.nextLabel)")
                    .font(.system(size: 11)).foregroundColor(Theme.accent).padding(.top, 2)
            }
        }
    }

    // Home-screen medium: stats + mini activity grid
    private var medium: some View {
        ZStack {
            Theme.bg
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.days)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Theme.level4, Theme.accent], startPoint: .top, endPoint: .bottom))
                    Text(entry.days == 1 ? "day sober" : "days sober")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Theme.textDim)
                    Text("🔥 \(entry.currentStreak) streak")
                        .font(.system(size: 12)).foregroundColor(Theme.text).padding(.top, 4)
                    if let m = entry.moneySaved, m > 0 {
                        Text("$\(Int(m).formatted()) saved")
                            .font(.system(size: 12)).foregroundColor(Theme.textDim)
                    }
                }
                Spacer()
                miniGrid
            }
            .padding(16)
        }
    }

    private var miniGrid: some View {
        HStack(spacing: 2) {
            ForEach(0..<13, id: \.self) { col in
                VStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { row in
                        let idx = col * 7 + row
                        RoundedRectangle(cornerRadius: 2)
                            .fill(idx < entry.recent.count && entry.recent[idx] ? Theme.level4 : Theme.surface2)
                            .frame(width: 9, height: 9)
                    }
                }
            }
        }
    }

    // Lock-screen circular: ring gauge with the day count
    private var circular: some View {
        Gauge(value: entry.progress) {
            Text("days")
        } currentValueLabel: {
            Text("\(entry.days)")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var inline: some View {
        Label("\(entry.days) days sober", systemImage: "leaf.fill")
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(entry.days) days sober").font(.headline)
            Text("🔥 \(entry.currentStreak) day streak · \(entry.remaining) to \(entry.nextLabel)")
                .font(.caption)
        }
    }
}

// MARK: - Widget

struct SoberWidget: Widget {
    let kind = "SoberWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SoberWidgetEntryView(entry: entry)
                .widgetBackgroundCompat()
        }
        .configurationDisplayName("Days Sober")
        .description("Your days sober, streak, and activity at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

private extension View {
    /// iOS 17 requires containerBackground for widgets; earlier versions don't have it.
    @ViewBuilder func widgetBackgroundCompat() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(Theme.bg, for: .widget)
        } else {
            self
        }
    }
}
