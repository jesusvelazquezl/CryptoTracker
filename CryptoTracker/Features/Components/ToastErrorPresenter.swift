//
//  ToastErrorPresenter.swift
//  CryptoTracker
//
//  Created by Jesus on 25/8/25.
//

import UIKit

enum ToastTheme {
    case standard               // uses .systemBackground
    case card                   // uses .secondarySystemBackground (like detail cards)
    case custom(background: UIColor, text: UIColor? = nil)
}

final class ToastErrorPresenter {
    private weak var hostView: UIView?
    private weak var activeToast: UIView?
    private let defaultTheme: ToastTheme

    init(hostView: UIView, theme: ToastTheme = .standard) {
        self.hostView = hostView
        self.defaultTheme = theme
    }

    func show(message: String, theme overrideTheme: ToastTheme? = nil) {
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

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.secondaryLabel, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissToast(_:)), for: .touchUpInside)

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self, weak toast] in
            guard let self = self, let toast = toast, toast.superview != nil else { return }
            guard self.activeToast === toast else { return }
            self.dismiss(toast: toast)
        }
    }

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

    @objc private func dismissToast(_ sender: UIButton) {
        guard let toast = sender.superview else { return }
        dismiss(toast: toast)
    }

    func dismiss() {
        guard let toast = activeToast else { return }
        dismiss(toast: toast)
    }
}
