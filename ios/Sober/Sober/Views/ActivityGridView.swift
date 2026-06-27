import SwiftUI

/// A GitHub-contributions-style grid of the selected year: 7 rows (weekdays)
/// × ~53 columns (weeks). Sober days light up green.
struct ActivityGridView: View {
    @EnvironmentObject var store: SobrietyStore
    @State private var year: Int = Calendar.current.component(.year, from: Date())

    private let cell: CGFloat = 12
    private let gap: CGFloat = 3
    private let monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        monthLabels
                        HStack(alignment: .top, spacing: 6) {
                            weekdayLabels
                            grid
                        }
                    }
                    .padding(.trailing, 4)
                }
                .onAppear { scrollToToday(proxy) }
                .onChange(of: year) { _ in scrollToToday(proxy) }
            }

            legend
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border))
        )
    }

    // MARK: - Header / year nav

    private var header: some View {
        HStack {
            Text("Activity")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.text)
            Spacer()
            HStack(spacing: 4) {
                navButton("chevron.left") { year -= 1 }
                Text(verbatim: "\(year)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text)
                    .frame(minWidth: 46)
                navButton("chevron.right") {
                    if year < currentYear + 1 { year += 1 }
                }
                .opacity(year < currentYear + 1 ? 1 : 0.3)
            }
        }
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.text)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.surface2)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border))
                )
        }
    }

    // MARK: - Grid

    private var grid: some View {
        let cols = weekColumns()
        return HStack(alignment: .top, spacing: gap) {
            ForEach(cols.indices, id: \.self) { i in
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { row in
                        cellView(cols[i][row])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ day: GridDay?) -> some View {
        if let day = day {
            RoundedRectangle(cornerRadius: 2)
                .fill(day.isSober ? Theme.level4 : Theme.level0)
                .frame(width: cell, height: cell)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(day.isToday ? Theme.text : Color.white.opacity(0.03),
                                      lineWidth: day.isToday ? 1.5 : 1)
                )
                .id(store.key(day.date))
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private var weekdayLabels: some View {
        let labels = ["", "Mon", "", "Wed", "", "Fri", ""]
        return VStack(alignment: .leading, spacing: gap) {
            ForEach(labels.indices, id: \.self) { i in
                Text(labels[i])
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textDim)
                    .frame(height: cell, alignment: .center)
            }
        }
        .frame(width: 24, alignment: .leading)
    }

    private var monthLabels: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 30)
            ForEach(monthSpans()) { span in
                Text(monthNames[span.month])
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textDim)
                    .frame(width: span.width, alignment: .leading)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Spacer()
            Text("Less").font(.system(size: 11)).foregroundColor(Theme.textDim)
            ForEach([Theme.level0, Theme.level1, Theme.level2, Theme.level3, Theme.level4], id: \.self) { c in
                RoundedRectangle(cornerRadius: 2).fill(c).frame(width: cell, height: cell)
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.border, lineWidth: 1))
            }
            Text("More").font(.system(size: 11)).foregroundColor(Theme.textDim)
        }
    }

    // MARK: - Data

    private struct GridDay {
        let date: Date
        let isSober: Bool
        let isToday: Bool
    }

    private struct MonthSpan: Identifiable {
        let id: Int      // month index 0-11
        var month: Int { id }
        let width: CGFloat
    }

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    /// Builds columns of 7 (Sun…Sat). Leading blanks pad Jan 1 to its weekday.
    private func weekColumns() -> [[GridDay?]] {
        let cal = Calendar.current
        var comps = DateComponents(); comps.year = year; comps.month = 1; comps.day = 1
        guard let jan1 = cal.date(from: comps) else { return [] }
        let todayStart = cal.startOfDay(for: Date())

        var cells: [GridDay?] = []
        let leadingBlanks = cal.component(.weekday, from: jan1) - 1 // weekday: 1=Sun
        cells.append(contentsOf: Array(repeating: nil, count: leadingBlanks))

        var day = jan1
        while cal.component(.year, from: day) == year {
            let k = store.key(day)
            let sober = day <= todayStart && store.isSober(k)
            let isToday = cal.isDate(day, inSameDayAs: Date())
            cells.append(GridDay(date: day, isSober: sober, isToday: isToday))
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        // pad to full final column
        while cells.count % 7 != 0 { cells.append(nil) }

        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0+7]) }
    }

    /// Assign each grid column to exactly one month (the month of its top day),
    /// so label widths sum to the grid width and don't drift across the year.
    private func monthSpans() -> [MonthSpan] {
        let columns = weekColumns()
        var perMonthColumns = Array(repeating: 0, count: 12)
        let cal = Calendar.current
        for column in columns {
            // month of the first real (non-blank) day in this column
            if let day = column.compactMap({ $0 }).first {
                let m = cal.component(.month, from: day.date) - 1
                perMonthColumns[m] += 1
            }
        }
        let colUnit = cell + gap
        return (0..<12).map { MonthSpan(id: $0, width: CGFloat(perMonthColumns[$0]) * colUnit) }
    }

    private func scrollToToday(_ proxy: ScrollViewProxy) {
        if year == currentYear {
            DispatchQueue.main.async {
                withAnimation { proxy.scrollTo(store.todayKey, anchor: .center) }
            }
        }
    }
}
