import SwiftUI

struct ApplyButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text("Apply")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled || isLoading)
    }
}
