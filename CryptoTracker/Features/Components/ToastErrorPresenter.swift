//
//  ToastErrorPresenter.swift
//  CryptoTracker
//
//  Created by Jesus on 25/8/25.
//

import UIKit

// MARK: - Theme

/// Visual theme for the toast.
enum ToastTheme {
    /// Background uses `.systemBackground`.
    case standard
    /// Background uses `.secondarySystemBackground` (good for card-like contrast).
    case card
    /// Fully custom colors.
    case custom(background: UIColor, text: UIColor? = nil)
}

// MARK: - Presenter

/// Presents a lightweight, dismissible toast anchored to the bottom safe area.
/// Safe against double-show, supports theming, and auto-dismiss.
final class ToastErrorPresenter {

    // MARK: State

    private weak var hostView: UIView?
    private weak var activeToast: UIView?
    private let defaultTheme: ToastTheme

    // MARK: Init

    /// - Parameters:
    ///   - hostView: The view where the toast will be added.
    ///   - theme: Default theme used when `show` is called without override (defaults to `.standard`).
    init(hostView: UIView, theme: ToastTheme = .standard) {
        self.hostView = hostView
        self.defaultTheme = theme
    }

    // MARK: API (backwards compatible)

    /// Shows a toast with the default duration (4s) and optional theme override.
    func show(message: String, theme overrideTheme: ToastTheme? = nil) {
        // Keep existing behavior: 4 seconds auto-dismiss
        show(message: message, theme: overrideTheme, duration: 4)
    }

    /// Shows a toast with a custom auto-dismiss duration.
    /// - Parameters:
    ///   - message: Text to display.
    ///   - overrideTheme: Optional theme to override the default one.
    ///   - duration: Seconds before auto-dismiss (use `<= 0` to disable auto-dismiss).
    func show(message: String, theme overrideTheme: ToastTheme? = nil, duration: TimeInterval) {
        guard let view = hostView else { return }
        // Avoid showing multiple toasts at the same time
        if let toast = activeToast, toast.superview != nil { return }

        // Resolve theme
        let theme = overrideTheme ?? defaultTheme

        // Toast container
        let toast = UIView()
        switch theme {
        case .standard:
            toast.backgroundColor = .systemBackground
        case .card:
            toast.backgroundColor = .secondarySystemBackground
        case .custom(let background, _):
            toast.backgroundColor = background
        }
        toast.layer.cornerRadius = 12
        toast.layer.cornerCurve = .continuous
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.isAccessibilityElement = false // label will be the a11y element

        // Label
        let label = UILabel()
        label.text = message
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = {
            switch theme {
            case .custom(_, let textColor):
                return textColor ?? .label
            default:
                return .label
            }
        }()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.isAccessibilityElement = true
        label.accessibilityLabel = message

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.secondaryLabel, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissToast(_:)), for: .touchUpInside)
        closeButton.accessibilityLabel = String(localized: "close")

        toast.addSubview(label)
        toast.addSubview(closeButton)

        view.addSubview(toast)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            toast.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            toast.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),

            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -12),

            closeButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: label.centerYAnchor)
        ])

        self.activeToast = toast

        // Initial state (hidden)
        toast.alpha = 0
        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        }

        // Announce for VoiceOver
        UIAccessibility.post(notification: .announcement, argument: message)

        // Auto-dismiss if duration > 0
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak toast] in
                guard
                    let self = self,
                    let toast = toast,
                    toast.superview != nil,
                    self.activeToast === toast
                else { return }
                self.dismiss(toast: toast)
            }
        }
    }

    // MARK: Private

    private func dismiss(toast: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            toast.alpha = 0
        }) { _ in
            toast.removeFromSuperview()
            if self.activeToast === toast {
                self.activeToast = nil
            }
        }
    }

    // MARK: Actions

    @objc private func dismissToast(_ sender: UIButton) {
        guard let toast = sender.superview else { return }
        dismiss(toast: toast)
    }

    // MARK: External Dismiss

    /// Dismisses the currently visible toast (if any).
    func dismiss() {
        guard let toast = activeToast else { return }
        dismiss(toast: toast)
    }
}
