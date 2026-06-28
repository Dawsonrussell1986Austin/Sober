import SwiftUI

/// "What's happening in your body" — a science-backed recovery timeline with a
/// countdown to the next milestone. Copy condensed from cited sources (see the
/// in-app Sources note); claims kept conservative where evidence is self-reported.
struct RecoveryTimelineView: View {
    @EnvironmentObject var store: SobrietyStore

    private struct Stage: Identifiable {
        let id: Int           // day threshold
        var day: Int { id }
        let label: String
        let title: String
        let detail: String
        let src: String
    }

    private let stages: [Stage] = [
        .init(id: 1,   label: "24 hours", title: "The clock starts",           detail: "Alcohol clears your system; hydration and headaches start to ease.", src: "Cleveland Clinic"),
        .init(id: 3,   label: "72 hours", title: "Past the hardest part",      detail: "Acute withdrawal peaks, then the physical symptoms begin to settle.", src: "Cleveland Clinic"),
        .init(id: 7,   label: "Week 1",   title: "Sleep & hydration rebound",  detail: "Acute withdrawal resolves; sleep starts to normalize and skin often looks brighter as you rehydrate.", src: "NIAAA · Cleveland Clinic"),
        .init(id: 14,  label: "2 weeks",  title: "Gut settles, BP eases",      detail: "Bloating eases as your gut lining recovers; blood pressure falls over roughly 2–4 weeks.", src: "Lancet Public Health, 2017"),
        .init(id: 21,  label: "3 weeks",  title: "Momentum building",          detail: "Energy and digestion keep improving — but 21 days forming a habit is a myth (see day 66).", src: "Lally et al., 2010"),
        .init(id: 30,  label: "1 month",  title: "Liver & metabolism improve", detail: "A month off alcohol measurably improves liver health, insulin resistance, weight and blood pressure.", src: "BMJ Open, 2018 (Royal Free)"),
        .init(id: 66,  label: "66 days",  title: "A habit actually forms",     detail: "Research puts automatic habit formation at a median of 66 days — the real number behind “21 days.”", src: "Lally et al., 2010"),
        .init(id: 90,  label: "3 months", title: "Your brain keeps rewiring",  detail: "Focus and memory keep improving; cravings ease over months as your reward system slowly rebalances.", src: "NIAAA · Volkow et al."),
        .init(id: 180, label: "6 months", title: "Cravings loosen their grip", detail: "Mood and reward circuitry keep recalibrating; cravings generally lessen substantially.", src: "NIAAA"),
        .init(id: 365, label: "1 year",   title: "Long-term risk drops",       detail: "Sustained sobriety lowers your risk of alcohol-related disease, including several cancers, over time.", src: "U.S. Surgeon General, 2025"),
    ]

    private let sources = [
        "Mehta et al., BMJ Open 2018 — Royal Free 1-month abstinence study",
        "Lally et al., 2010, Eur. J. Social Psychology — habit formation (median 66 days)",
        "Volkow et al. — dopamine D2 receptor recovery (PET studies)",
        "NIAAA — neuroscience of addiction & recovery; alcohol & sleep",
        "Roerecke et al., Lancet Public Health 2017 — alcohol & blood pressure",
        "Cleveland Clinic — alcohol withdrawal timeline",
        "U.S. Surgeon General, 2025 — Alcohol & Cancer Risk Advisory",
    ]

    var body: some View {
        let n = store.daysSober
        let next = stages.first { n < $0.day }

        VStack(alignment: .leading, spacing: 14) {
            Text("What's happening in your body")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)

            nextBanner(n: n, next: next)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(stages) { stage in
                    row(stage, n: n, isNext: next?.id == stage.id)
                }
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    Text("General information, not medical advice. Recovery varies by person. If you drink heavily or daily, stopping suddenly can be dangerous (seizures / delirium tremens) — talk to a doctor about safe detox.")
                        .font(.system(size: 12)).foregroundColor(Theme.textDim)
                    ForEach(sources, id: \.self) { s in
                        Text("• \(s)").font(.system(size: 11)).foregroundColor(Theme.textDim)
                    }
                }
                .padding(.top, 6)
            } label: {
                Text("Sources & medical note").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.textDim)
            }
            .tint(Theme.textDim)
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border)))
    }

    @ViewBuilder
    private func nextBanner(n: Int, next: Stage?) -> some View {
        if let nx = next {
            let left = nx.day - n
            VStack(alignment: .leading, spacing: 3) {
                (Text("Next up in ").foregroundColor(Theme.text)
                 + Text("\(left) \(left == 1 ? "day" : "days")").foregroundColor(Theme.accent).bold()
                 + Text(" · \(nx.label): \(nx.title)").foregroundColor(Theme.text))
                    .font(.system(size: 13, weight: .semibold))
                Text(nx.detail).font(.system(size: 12.5)).foregroundColor(Theme.textDim)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface2)
                .overlay(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [Theme.accent.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom)))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.accent)))
        } else {
            Text("You've passed every milestone here. 🏆 Your body and brain keep healing well beyond a year.")
                .font(.system(size: 13)).foregroundColor(Theme.text)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.accent)))
        }
    }

    private func row(_ stage: Stage, n: Int, isNext: Bool) -> some View {
        let reached = n >= stage.day
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(reached ? Theme.accent : Theme.surface2)
                    .overlay(Circle().strokeBorder(reached || isNext ? Theme.accent : Theme.border, lineWidth: isNext ? 2 : 1))
                    .frame(width: 22, height: 22)
                if reached {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(stage.label) · \(stage.title)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(reached || isNext ? Theme.text : Theme.textDim)
                    Spacer(minLength: 6)
                    Text(reached ? "✓ reached" : "in \(stage.day - n)d")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(reached ? Theme.level4 : (isNext ? Theme.accent : Theme.textDim))
                }
                Text(stage.detail).font(.system(size: 12.5)).foregroundColor(Theme.textDim)
                Text(stage.src).font(.system(size: 10)).foregroundColor(Theme.textDim.opacity(0.7))
            }
        }
        .padding(.bottom, 14)
    }
}
