import SwiftUI

struct HarborPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(HarborColors.calmTeal)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct HarborAvatar: View {
    let member: HarborMember
    var size: CGFloat = 48
    var selected = false

    var body: some View {
        ZStack {
            if selected {
                Circle()
                    .fill(member.tint.opacity(0.18))
                    .frame(width: size + 18, height: size + 18)
            }

            Circle()
                .fill(member.tint)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .fill(member.tint.opacity(0.16))
                        .padding(4)
                        .overlay {
                            Text(member.initials)
                                .font(.system(size: size * 0.34, weight: .semibold))
                                .foregroundStyle(member.tint)
                        }
                }
                .overlay {
                    Circle().stroke(.white, lineWidth: 3)
                }

            Circle()
                .fill(statusColor)
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .offset(x: size * 0.36, y: -size * 0.36)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(member.name), \(member.presence.rawValue)")
    }

    private var statusColor: Color {
        switch member.presence {
        case .live, .recent, .arrived: HarborColors.safeGreen
        case .travelling: HarborColors.clearSky
        case .delayed: HarborColors.warmAmber
        case .offline, .paused: HarborColors.slate
        }
    }
}

struct HarborStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
