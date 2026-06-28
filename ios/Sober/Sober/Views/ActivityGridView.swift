import SwiftUI

private struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// A GitHub-contributions-style grid of the selected year. Cells are sized to
/// fit the entire year within the card width — no horizontal scrolling.
struct ActivityGridView: View {
    @EnvironmentObject var store: SobrietyStore
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var gridWidth: CGFloat = 0

    private let monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            // full-width measuring strip
            Color.clear.frame(height: 0)
                .background(GeometryReader { g in
                    Color.clear.preference(key: WidthKey.self, value: g.size.width)
                })

            if gridWidth > 0 {
                let layout = computeLayout()
                monthLabels(layout)
                grid(layout)
                footer(layout)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border)))
        .onPreferenceChange(WidthKey.self) { gridWidth = $0 }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Activity").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
            Spacer()
            HStack(spacing: 4) {
                navButton("chevron.left") { year -= 1 }
                Text(verbatim: "\(year)").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text).frame(minWidth: 46)
                navButton("chevron.right") { if year < currentYear + 1 { year += 1 } }
                    .opacity(year < currentYear + 1 ? 1 : 0.3)
            }
        }
    }
    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface2).overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border)))
        }
    }

    // MARK: - Grid
    private func grid(_ layout: Layout) -> some View {
        HStack(alignment: .top, spacing: layout.gap) {
            ForEach(layout.columns.indices, id: \.self) { ci in
                VStack(spacing: layout.gap) {
                    ForEach(0..<7, id: \.self) { row in
                        cell(layout.columns[ci][row], size: layout.cell)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ day: GridDay?, size: CGFloat) -> some View {
        if let day = day {
            RoundedRectangle(cornerRadius: 2)
                .fill(day.isSober ? Theme.level4 : Theme.level0)
                .frame(width: size, height: size)
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(day.isToday ? Theme.text : Color.white.opacity(0.04), lineWidth: day.isToday ? 1.5 : 1))
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }

    private func monthLabels(_ layout: Layout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.monthMarks, id: \.month) { mark in
                Text(monthNames[mark.month])
                    .font(.system(size: 10)).foregroundColor(Theme.textDim)
                    .offset(x: CGFloat(mark.column) * layout.pitch)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 12)
    }

    private func footer(_ layout: Layout) -> some View {
        HStack {
            Text("\(layout.soberCount) sober \(layout.soberCount == 1 ? "day" : "days") in \(year)")
                .font(.system(size: 11)).foregroundColor(Theme.textDim)
            Spacer()
            HStack(spacing: 4) {
                Text("Less").font(.system(size: 11)).foregroundColor(Theme.textDim)
                ForEach([Theme.level0, Theme.level1, Theme.level2, Theme.level3, Theme.level4], id: \.self) { c in
                    RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 11, height: 11)
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.border, lineWidth: 1))
                }
                Text("More").font(.system(size: 11)).foregroundColor(Theme.textDim)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Layout / data
    private struct GridDay { let date: Date; let isSober: Bool; let isToday: Bool }
    private struct MonthMark { let month: Int; let column: Int }
    private struct Layout {
        let columns: [[GridDay?]]
        let cell: CGFloat
        let gap: CGFloat
        let monthMarks: [MonthMark]
        let soberCount: Int
        var pitch: CGFloat { cell + gap }
    }

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private func computeLayout() -> Layout {
        let cal = Calendar.current
        var comps = DateComponents(); comps.year = year; comps.month = 1; comps.day = 1
        let jan1 = cal.date(from: comps)!
        let todayStart = cal.startOfDay(for: Date())
        let leadingBlanks = cal.component(.weekday, from: jan1) - 1

        var cells: [GridDay?] = Array(repeating: nil, count: leadingBlanks)
        var soberCount = 0
        var day = jan1
        while cal.component(.year, from: day) == year {
            let k = store.key(day)
            let sober = day <= todayStart && store.isSober(k)
            if sober { soberCount += 1 }
            cells.append(GridDay(date: day, isSober: sober, isToday: cal.isDate(day, inSameDayAs: Date())))
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        let columns = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0+7]) }

        // size cells (and gap) to fit the year within the measured width
        let numCols = columns.count
        let gapsTotal = CGFloat(numCols - 1)
        var cell = floor((gridWidth - gapsTotal * 2) / CGFloat(numCols))
        var gap = max(1, min(3, (cell / 4).rounded()))
        cell = floor((gridWidth - gapsTotal * gap) / CGFloat(numCols))
        cell = max(3, min(cell, 15))
        while CGFloat(numCols) * cell + gapsTotal * gap > gridWidth && cell > 3 { cell -= 1 }

        // month marks: month of the first real day in each column
        var marks: [MonthMark] = []
        var seen = Set<Int>()
        for (ci, col) in columns.enumerated() {
            if let d = col.compactMap({ $0 }).first {
                let m = cal.component(.month, from: d.date) - 1
                if !seen.contains(m) { seen.insert(m); marks.append(MonthMark(month: m, column: ci)) }
            }
        }

        return Layout(columns: columns, cell: cell, gap: gap, monthMarks: marks, soberCount: soberCount)
    }
}
