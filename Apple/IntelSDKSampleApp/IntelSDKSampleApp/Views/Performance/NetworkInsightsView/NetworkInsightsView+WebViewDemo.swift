//
//  NetworkInsightsView+WebViewDemo.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

extension NetworkInsightsView {

    // MARK: - Section: WKWebView Demo

    var webViewDemoSection: some View {
        Section {
            self.webViewInfoCallout

            if self.manager.monitorWKWebView {
                self.webViewInteractiveContent
            } else {
                self.webViewDisabledMessage
            }
        } header: {
            SectionHeaderView(
                title: "Monitor WKWebView & Web View Demo",
                systemImage: "globe.badge.chevron.backward",
                description: "When Monitor WKWebView is enabled in WS1Config, the SDK automatically captures network traffic from embedded web views — page loads, transitions, and JavaScript-initiated requests."
            )
        } footer: {
            if self.manager.monitorWKWebView {
                Text("Network traffic from this web view (page loads and JS requests) is automatically captured by the SDK when Monitor WKWebView is enabled.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Info Callout

    private var webViewInfoCallout: some View {
        InfoRowView(
            icon: "info.circle.fill",
            color: .blue,
            title: "Importance of Monitor WKWebView",
            infoBody: "Monitor WKWebView must be enabled in WS1Config before SDK initialization. When enabled, network traffic from WKWebView (page loads, transitions, and JavaScript-initiated requests) is automatically captured — no manual logging needed. It is disabled by default because enabling it triggers WKWebView class initialization (background thread) even in apps that never use web views."
        )
    }

    // MARK: - Interactive Web View (when Monitor WKWebView is enabled)

    private var webViewInteractiveContent: some View {
        Group {
            HStack(spacing: 8) {
                TextField("https://yahoo.com", text: self.$webViewURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button("Load") {
                    self.loadWebViewURL()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!self.isValidWebViewURL)
            }

            if let url = self.webViewDisplayURL {
                WKWebViewRepresentable(url: url)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Disabled Message (when Monitor WKWebView is off)

    private var webViewDisabledMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.title3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text("Monitor WKWebView was disabled when the SDK was initialized.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Restart the app and enable it on the Dashboard to see automatic capture of web view network traffic.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.orange.opacity(0.06))
    }

    // MARK: - Helpers

    private var isValidWebViewURL: Bool {
        self.parsedWebViewURL != nil
    }

    private var parsedWebViewURL: URL? {
        let trimmed = self.webViewURLString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { 
            return nil 
        }

        guard let url = URL(string: trimmed), let scheme = url.scheme, scheme == "https" else {
            return nil
        }

        return url
    }

    private func loadWebViewURL() {
        guard let url = self.parsedWebViewURL else {
            return
        }
        self.webViewDisplayURL = url
        self.toastMessage = "Loading \(url.host ?? url.absoluteString)…"
    }
}
