import SwiftUI

struct PickerField: View {
    let title: String
    let placeholder: String
    let options: [String]
    @Binding var selection: String?

    @State private var showSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3).bold()

            Button {
                showSheet = true
            } label: {
                HStack {
                    Text(selection ?? placeholder)
                        .foregroundStyle(selection == nil ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSheet) {
            SelectionSheet(
                title: title,
                options: options
            ) { value in
                selection = value
                showSheet = false
            }
            .presentationDetents([.medium]) // minimal; remove or add .large if you like
        }
    }
}
