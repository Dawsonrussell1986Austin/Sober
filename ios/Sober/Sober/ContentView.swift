import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: SobrietyStore
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    counterCard
                    checkInCard
                    statsRow
                    ActivityGridView()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Sober")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.text)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.textDim)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Counter

    private var counterCard: some View {
        VStack(spacing: 6) {
            Text("\(store.daysSober)")
                .font(.system(size: 88, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.level4, Theme.accent],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Theme.accent.opacity(0.4), radius: 24)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.daysSober)

            Text(store.daysSober == 1 ? "day sober" : "days sober")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.textDim)

            Text(sinceText)
                .font(.system(size: 13))
                .foregroundColor(Theme.textDim.opacity(0.8))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            RadialGradient(colors: [Theme.accent.opacity(0.15), .clear],
                                           center: .top, startRadius: 0, endRadius: 220)
                        )
                )
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border))
        )
    }

    private var sinceText: String {
        guard let s = store.startDate else { return "Set your start date in settings" }
        let f = DateFormatter()
        f.dateStyle = .long
        return "since " + f.string(from: s)
    }

    // MARK: - Check-in

    private var checkInCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.isCheckedInToday ? "You showed up today" : "Stay strong today")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(store.isCheckedInToday
                     ? "One more sober day in the books. Keep going."
                     : "Tap to log that you stayed sober today.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation { store.checkInToday() }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text(store.isCheckedInToday ? "✓ Done" : "Check in")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(store.isCheckedInToday ? Theme.accent : .white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(store.isCheckedInToday ? Theme.surface2 : Theme.accent)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(store.isCheckedInToday ? Theme.accent : .clear)
                            )
                    )
            }
            .disabled(store.isCheckedInToday)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
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
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.text)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border))
        )
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border))
    }
}

#Preview {
    ContentView().environmentObject(SobrietyStore())
}
