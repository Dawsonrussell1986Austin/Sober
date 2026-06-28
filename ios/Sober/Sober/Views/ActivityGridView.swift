import SwiftUI
import UIKit

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
    @State private var showEdit = false

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

            Button { showEdit = true } label: {
                Text("✎ Forgot a day? Edit a past day")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.textDim)
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface2).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border)))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16).padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border)))
        .onPreferenceChange(WidthKey.self) { gridWidth = $0 }
        .sheet(isPresented: $showEdit) { EditDayView().environmentObject(store) }
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
                .contentShape(Rectangle())
                .onTapGesture { if day.editable { store.toggleDay(store.key(day.date)) } }
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
    private struct GridDay { let date: Date; let isSober: Bool; let isToday: Bool; let editable: Bool }
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
            cells.append(GridDay(date: day, isSober: sober,
                                 isToday: cal.isDate(day, inSameDayAs: Date()),
                                 editable: day <= todayStart))
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

/// Pick a date and toggle whether you were sober that day (backfill forgotten days).
private struct EditDayView: View {
    @EnvironmentObject var store: SobrietyStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accentColor(Theme.accent)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border)))

                    let key = store.key(date)
                    let count = store.drinkCount(on: key)
                    let sober = store.isSober(key)
                    HStack {
                        Spacer()
                        Text(count > 0 ? "🍷 \(count)\(count >= 3 ? "+" : "") drink\(count > 1 ? "s" : "")"
                                       : (sober ? "● Sober day" : "○ Not marked"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(count > 0 ? Theme.textDim : (sober ? Theme.level4 : Theme.textDim))
                        Spacer()
                    }

                    if store.mode222 {
                        Text("Drinks that day").font(.system(size: 13)).foregroundColor(Theme.textDim)
                        HStack(spacing: 8) {
                            ForEach(0..<4) { n in
                                Button {
                                    store.setDrinks(key, n)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Text(n == 3 ? "3+" : "\(n)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(count == n ? Color(hex: 0x160b04) : Theme.text)
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(count == n ? Theme.accent : Theme.bg)
                                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Button {
                            store.toggleDay(key)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(sober ? "I had a drink" : "I was sober")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accent))
                        }
                    }

                    Text("Tip: you can also tap any day in the grid to toggle it.")
                        .font(.system(size: 12)).foregroundColor(Theme.textDim)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
