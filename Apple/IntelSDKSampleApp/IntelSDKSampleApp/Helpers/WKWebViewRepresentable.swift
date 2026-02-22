//
//  WKWebViewRepresentable.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WebKit

// MARK: - WKWebViewRepresentable

/// A SwiftUI wrapper for WKWebView used to demonstrate automatic network capture
/// when MonitorWKWebView is enabled in WS1Config.
///
/// The WS1 Intelligence SDK automatically intercepts WKWebView.loadRequest(_:)
/// when monitorWKWebView is true. No special hooks or delegates are required —
/// simply loading a URL in this web view will result in the SDK capturing the
/// network traffic (page loads, transitions, and JavaScript-initiated requests).
struct WKWebViewRepresentable: UIViewRepresentable {

    /// The URL to load. When this changes, the web view loads the new URL.
    let url: URL

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.lastLoadedURL != self.url {
            coordinator.lastLoadedURL = self.url
            let request = URLRequest(url: self.url)
            // loadRequest(_:) is the API the SDK intercepts when monitorWKWebView is enabled.
            // All network traffic from this load (and subsequent JS requests) is automatically
            // captured by the Intelligence SDK — no manual logging required.
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        /// Tracks the last URL we loaded to avoid redundant loads on SwiftUI updates.
        var lastLoadedURL: URL?
    }
}
