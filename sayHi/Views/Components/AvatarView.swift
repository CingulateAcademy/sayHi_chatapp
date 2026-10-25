import SwiftUI

struct AvatarView: View {
    let photoURL: String
    let name: String
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let url = URL(string: photoURL), !photoURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return (first + last).uppercased()
    }
}
