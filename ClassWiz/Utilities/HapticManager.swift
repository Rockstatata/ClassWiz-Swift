// HapticManager.swift
// ClassWiz

import UIKit

enum HapticManager {
    // MARK: - Impact

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func lightImpact()  { impact(.light) }
    static func mediumImpact() { impact(.medium) }
    static func heavyImpact()  { impact(.heavy) }

    // MARK: - Notification

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func success() { notification(.success) }
    static func warning() { notification(.warning) }
    static func error()   { notification(.error) }

    // MARK: - Selection

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
