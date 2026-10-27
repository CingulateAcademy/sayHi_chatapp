import SwiftUI

struct SplashView: View {
    @State private var markScale: CGFloat = 0.55
    @State private var markOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12

    var body: some View {
        ZStack {
            // Background matches the logo
            Color(red: 0.15, green: 0.10, blue: 0.38)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width:140, height:140)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                
                Text("sayHi")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                markScale = 1.0
                markOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }
    }
}



#Preview {
    SplashView()
}


