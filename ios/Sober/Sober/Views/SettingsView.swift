import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SobrietyStore
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var spendText: String = ""
    @State private var hoursText: String = ""
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        field("Sobriety start date") {
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .accentColor(Theme.accent)
                                .onChange(of: date) { newValue in store.startDate = newValue }
                        }

                        HStack(spacing: 12) {
                            field("Money saved / day") {
                                inputRow(prefix: "$", text: $spendText) { commitSpend() }
                            }
                            field("Hours saved / day") {
                                inputRow(prefix: nil, text: $hoursText) { commitHours() }
                            }
                        }

                        Text("Every day from your start date counts as sober automatically. Set a daily figure to see the money and time you've reclaimed.")
                            .font(.system(size: 13)).foregroundColor(Theme.textDim)

                        Button(role: .destructive) { showResetAlert = true } label: {
                            Text("Reset all data")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.danger)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.danger))
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commitSpend(); commitHours(); dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                date = store.startDate ?? Date()
                spendText = store.dailySpend.map { trim($0) } ?? ""
                hoursText = store.dailyHours.map { trim($0) } ?? ""
            }
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.reset(); date = Date(); spendText = ""; hoursText = ""; dismiss()
                }
            } message: {
                Text("This permanently clears your start date, check-ins, and settings.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - building blocks
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14)).foregroundColor(Theme.textDim)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inputRow(prefix: String?, text: Binding<String>, onCommit: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            if let p = prefix { Text(p).foregroundColor(Theme.textDim) }
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .foregroundColor(Theme.text)
                .onSubmit(onCommit)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bg).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border)))
    }

    private func commitSpend() {
        let v = Double(spendText.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces))
        store.dailySpend = (v ?? 0) > 0 ? v : nil
    }
    private func commitHours() {
        let v = Double(hoursText.trimmingCharacters(in: .whitespaces))
        store.dailyHours = (v ?? 0) > 0 ? v : nil
    }
    private func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

#Preview {
    SettingsView().environmentObject(SobrietyStore())
}
