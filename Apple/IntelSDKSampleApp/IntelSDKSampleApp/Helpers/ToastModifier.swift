//
//  ToastModifier.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// A view modifier that displays a toast message overlay at the bottom of the view.
///
/// When `message` is non-nil, the toast is shown. It auto-dismisses after `duration` seconds.
/// Set `message` to a non-nil string to present; the modifier clears it after the duration.
struct ToastModifier: ViewModifier {

    @Binding var message: String?
    var duration: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let msg = self.message {
                    Text(msg)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: self.message)
            .task(id: self.message) {
                guard self.message != nil else {
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(self.duration * 1_000_000_000))
                self.message = nil
            }.onDisappear {
                self.message = nil
            }
    }
}

extension View {

    /// Presents a toast overlay when `message` is non-nil. Auto-dismisses after `duration` seconds.
    ///
    /// - Parameters:
    ///   - message: Binding to the toast message. Set to a non-nil string to present; the modifier clears it after duration.
    ///   - duration: Seconds until auto-dismiss. Default 2.0.
    func toast(message: Binding<String?>, duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(message: message, duration: duration))
    }
}
