import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SobrietyStore
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sobriety start date")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textDim)
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(Theme.accent)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
                            )
                            .onChange(of: date) { newValue in
                                store.startDate = newValue
                            }
                    }

                    Text("Every day from your start date counts as sober automatically. You can also tap “Check in” each day.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textDim)

                    Spacer()

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Reset all data")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.danger)
                            )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear { date = store.startDate ?? Date() }
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.reset()
                    date = Date()
                    dismiss()
                }
            } message: {
                Text("This permanently clears your start date and all check-ins.")
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView().environmentObject(SobrietyStore())
}
