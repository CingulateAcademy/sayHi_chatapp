import SwiftUI
struct BrandHeaderView: View {
    var title: String = "sayHi"
    var iconName: String = "bubble.left.and.bubble.right.fill"
    
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.sayHiIndigo, Color.sayHiIndigoLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.sayHiIndigo.opacity(0.4), radius: 12, y: 6)

                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.sayHiIndigo)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.85)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}
