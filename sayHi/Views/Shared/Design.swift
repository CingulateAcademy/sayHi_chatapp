import SwiftUI

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}



enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}


extension Color {
    static let sayHiIndigo = Color(red: 0.15, green: 0.10, blue: 0.38)
    static let sayHiIndigoLight = Color(red: 0.28, green: 0.20, blue: 0.58)
    static let sayHiPurple = Color(red: 0.70, green: 0.55, blue: 0.95)
    static let sayHiTeal = Color(red: 0.15, green: 0.75, blue: 0.85)

    static let sayHiBubbleSent = Color.accentColor
    static let sayHiBubbleReceived = Color(.secondarySystemBackground)
    static let sayHiSurface = Color(.secondarySystemBackground)
    static let sayHiSeparator = Color(.separator).opacity(0.35)
}


enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
