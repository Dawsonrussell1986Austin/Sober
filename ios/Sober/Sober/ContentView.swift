import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: SobrietyStore
    @State private var showSettings = false
    @State private var showConfetti = false
    @State private var celebrateText: String?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    heroRing
                    checkInCard
                    statsRow
                    savingsCard
                    milestonesRow
                    RecoveryTimelineView()
                    ActivityGridView()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            if showConfetti {
                ConfettiView().transition(.opacity)
                if let text = celebrateText {
                    VStack {
                        Text(text)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 18).padding(.vertical, 12)
                            .background(Capsule().fill(Theme.surface2).overlay(Capsule().strokeBorder(Theme.accent)))
                            .padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store) }
        .onAppear(perform: celebrateIfNeeded)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Sober").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundColor(Theme.textDim)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Hero ring
    private var ringProgress: Double {
        let n = store.daysSober
        let m = Milestones.next(after: n)
        let span = Double(m.next - m.prev)
        guard span > 0 else { return 0 }
        return min(1, max(0, Double(n - m.prev) / span))
    }

    private var heroRing: some View {
        let n = store.daysSober
        let m = Milestones.next(after: n)
        let remaining = m.next - n
        return VStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.surface2, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.accent.opacity(0.4), radius: 6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.9), value: ringProgress)
                VStack(spacing: 2) {
                    Text("\(n)")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .top, endPoint: .bottom))
                        .contentTransition(.numericText())
                    Text(n == 1 ? "day sober" : "days sober")
                        .font(.system(size: 15, weight: .medium)).foregroundColor(Theme.textDim)
                    Text(sinceText).font(.system(size: 12)).foregroundColor(Theme.textDim.opacity(0.8))
                }
            }
            .frame(width: 224, height: 224)
            .padding(.top, 6)

            Text(milestoneCaption(remaining: remaining, next: m.next))
                .font(.system(size: 13)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 22).fill(
                    RadialGradient(colors: [Theme.accent.opacity(0.13), .clear], center: .top, startRadius: 0, endRadius: 220)))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.border))
        )
    }

    private func milestoneCaption(remaining: Int, next: Int) -> AttributedString {
        if store.startDate == nil && store.daysSober == 0 {
            return AttributedString("Your journey starts today.")
        }
        return AttributedString("\(remaining) \(remaining == 1 ? "day" : "days") to \(Milestones.label(next))")
    }

    private var sinceText: String {
        guard let s = store.data.streakStartDate else { return "tap a day or check in to start" }
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return "since " + f.string(from: s)
    }

    // MARK: - Check-in
    private var checkInCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.isCheckedInToday ? "You showed up today" : "Stay strong today")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                Text(store.isCheckedInToday ? "One more sober day in the books. Keep going."
                                            : "Tap to log that you stayed sober today.")
                    .font(.system(size: 13)).foregroundColor(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation { store.checkInToday() }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                celebrateIfNeeded()
            } label: {
                Text(store.isCheckedInToday ? "✓ Done" : "Check in")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(store.isCheckedInToday ? Theme.accent : .white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(store.isCheckedInToday ? Theme.surface2 : Theme.accent)
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(store.isCheckedInToday ? Theme.accent : .clear)))
            }
            .disabled(store.isCheckedInToday)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(card)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 10) {
            stat("\(store.currentStreak)", "Current streak")
            stat("\(store.bestStreak)", "Best streak")
            stat("\(store.totalDays)", "Total days")
        }
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
            Text(label).font(.system(size: 11)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border)))
    }

    // MARK: - Savings
    private var savingsCard: some View {
        let money = store.moneySaved
        let hours = store.hoursSaved
        return VStack(alignment: .leading, spacing: 12) {
            Text("WHAT YOU'VE RECLAIMED")
                .font(.system(size: 12, weight: .semibold)).tracking(0.4).foregroundColor(Theme.textDim)
            HStack(spacing: 16) {
                savingsItem(value: "$" + Int(money).formatted(),
                            sub: "not spent · $\(trim(store.data.effectiveDailySpend))/day")
                if let h = hours, h > 0 {
                    savingsItem(value: prettyHours(h), sub: "reclaimed · \(trim(store.dailyHours ?? 0))h/day")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Theme.accent.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border)))
    }
    private func savingsItem(value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text)
            Text(sub).font(.system(size: 12)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func prettyHours(_ h: Double) -> String {
        let days = Int(h) / 24, hrs = Int(h) % 24
        return days > 0 ? "\(days)d \(hrs)h" : "\(Int(h.rounded()))h"
    }
    private func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - Milestone badges
    private var milestonesRow: some View {
        HStack(spacing: 8) {
            ForEach(Milestones.badges) { b in
                let reached = store.daysSober >= b.days
                VStack(spacing: 5) {
                    Text(b.icon).font(.system(size: 16)).grayscale(reached ? 0 : 1).opacity(reached ? 1 : 0.5)
                    Text(b.label).font(.system(size: 10, weight: .semibold)).foregroundColor(reached ? Theme.text : Theme.textDim)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(reached ? Theme.surface : Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: reached ? [Theme.accent.opacity(0.14), .clear] : [.clear, .clear], startPoint: .top, endPoint: .bottom)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(reached ? Theme.accent : Theme.border)))
            }
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border))
    }

    // MARK: - Celebration
    private func celebrateIfNeeded() {
        guard let m = store.newlyReachedMilestone() else { return }
        celebrateText = "\(m.icon) \(m.label) milestone! Incredible."
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showConfetti = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            withAnimation { showConfetti = false }
        }
    }
}

#Preview {
    ContentView().environmentObject(SobrietyStore())
}
