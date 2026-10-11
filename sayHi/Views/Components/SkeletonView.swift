import SwiftUI

struct SkeletonView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray6),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

struct ConversationSkeletonRow: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView()
                    .frame(width: 120, height: 14)
                SkeletonView()
                    .frame(width: 180, height: 12)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}


