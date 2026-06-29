import SwiftUI

/// A tap-to-pick month calendar that shades sober days orange (matching the web
/// version). Future days are disabled; the selected day shows a ring.
struct CalendarPickerView: View {
    @Binding var selected: Date
    var maxDate: Date = Date()
    var isSober: (Date) -> Bool

    @State private var month: Date

    private let cal = Calendar.current
    private static let titleFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f
    }()

    init(selected: Binding<Date>, maxDate: Date = Date(), isSober: @escaping (Date) -> Bool) {
        self._selected = selected
        self.maxDate = maxDate
        self.isSober = isSober
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: selected.wrappedValue)
        self._month = State(initialValue: cal.date(from: comps) ?? selected.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
            HStack(spacing: 4) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Text(weekdays[i]).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                }
            }
            let weeks = monthWeeks()
            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { c in dayCell(weeks[wi][c]) }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.bg).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border)))
    }

    private var header: some View {
        HStack {
            navButton("chevron.left", enabled: true) {
                month = cal.date(byAdding: .month, value: -1, to: month)!
            }
            Spacer()
            Text(Self.titleFormatter.string(from: month))
                .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text)
            Spacer()
            navButton("chevron.right", enabled: canGoNext) {
                if canGoNext { month = cal.date(byAdding: .month, value: 1, to: month)! }
            }
        }
    }

    private func navButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.surface2).overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.border)))
        }
        .opacity(enabled ? 1 : 0.3)
        .disabled(!enabled)
    }

    private var canGoNext: Bool {
        let next = cal.date(byAdding: .month, value: 1, to: month)!
        return cal.compare(next, to: maxDate, toGranularity: .month) != .orderedDescending
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date = date {
            let disabled = cal.startOfDay(for: date) > cal.startOfDay(for: maxDate)
            let sober = !disabled && isSober(date)
            let isSel = cal.isDate(date, inSameDayAs: selected)
            let isToday = cal.isDateInToday(date)
            Button { if !disabled { selected = date } } label: {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 13, weight: isSel ? .bold : .regular))
                    .foregroundColor(disabled ? Theme.textDim.opacity(0.4) : (sober ? Color(hex: 0x160b04) : Theme.text))
                    .frame(maxWidth: .infinity).frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(sober ? Theme.level4 : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(isSel ? Theme.text : (isToday ? Theme.accent : Color.clear),
                                              lineWidth: isSel ? 2 : 1.5))
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        } else {
            Color.clear.frame(height: 36)
        }
    }

    private func monthWeeks() -> [[Date?]] {
        let comps = cal.dateComponents([.year, .month], from: month)
        let first = cal.date(from: comps)!
        let leading = cal.component(.weekday, from: first) - 1
        let count = cal.range(of: .day, in: .month, for: first)!.count
        var days: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<count { days.append(cal.date(byAdding: .day, value: d, to: first)) }
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0 + 7]) }
    }
}
