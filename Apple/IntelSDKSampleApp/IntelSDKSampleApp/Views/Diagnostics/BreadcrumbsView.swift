//
//  BreadcrumbsView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - Supporting Types

/// A single breadcrumb entry recorded during the current session.
/// Used for the local session history list only — not persisted to disk.
private struct BreadcrumbEntry: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
}

// MARK: - BreadcrumbsView

/// Demonstrates the WS1 Intelligence SDK breadcrumb feature.
///
/// Breadcrumbs are developer-defined text strings (up to 140 characters) that are
/// timestamped and attached to crash reports and user flow traces. They answer the
/// question "what was the user doing just before the crash?" without requiring a full
/// event-logging system. This view exposes:
///
/// - A free-form text field to leave a custom breadcrumb
/// - An async-mode toggle to trade write-durability for performance
/// - Quick-action buttons for common lifecycle breadcrumbs
/// - A session history list showing every breadcrumb left during the current run
struct BreadcrumbsView: View {

    @Environment(IntelSDKManager.self) private var manager

    @State private var breadcrumbText: String = ""
    @State private var isAsyncMode: Bool = false
    @State private var history: [BreadcrumbEntry] = []
    @State private var toastMessage: String?

    private let maxLength = 140
    private static let quickActionLabels: [String] = [
        "App Launched",
        "User Logged In",
        "Settings Opened",
        "Payment Initiated",
        "Data Synced"
    ]

    var body: some View {
        Form {
            self.leaveSection
            self.asyncModeSection
            self.quickActionsSection
            self.historySection
        }
        .navigationTitle("Breadcrumbs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !self.history.isEmpty {
                    Button("Clear History") {
                        self.history.removeAll()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .toast(message: self.$toastMessage, duration: 1.5)
    }

    // MARK: - Leave a Breadcrumb Section

    private var leaveSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter breadcrumb text…", text: self.$breadcrumbText, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .onChange(of: self.breadcrumbText) { _, newValue in
                        if newValue.count > self.maxLength {
                            self.breadcrumbText = String(newValue.prefix(self.maxLength))
                        }
                    }

                HStack {
                    Spacer()
                    Text("\(self.breadcrumbText.count) / \(self.maxLength)")
                        .font(.caption)
                        .foregroundStyle(self.breadcrumbText.count >= self.maxLength ? .red : .secondary)
                }
            }

            Button {
                self.leaveBreadcrumb(self.breadcrumbText)
                self.breadcrumbText = ""
            } label: {
                HStack {
                    Spacer()
                    Label("Leave Breadcrumb", systemImage: "bookmark.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(self.breadcrumbText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } header: {
            SectionHeaderView(
                title: "Leave a Breadcrumb",
                systemImage: "bookmark",
                description: "Log a free-form text string (up to 140 characters) timestamped at the moment of the call. Breadcrumbs appear in crash reports to provide context about what the user was doing."
            )
        } footer: {
            Text("Breadcrumbs are limited to 140 characters. They are also automatically associated with any active user flow at the time they are logged.")
                .font(.caption)
        }
    }

    // MARK: - Async Mode Section

    private var asyncModeSection: some View {
        Section {
            Toggle(isOn: self.$isAsyncMode) {
                Label("Async Breadcrumb Mode", systemImage: "arrow.trianglehead.2.clockwise")
            }
            .onChange(of: self.isAsyncMode) { _, newValue in
                // WS1Intelligence.setAsyncBreadcrumbMode(_:)
                // By default (false), breadcrumbs are written to disk synchronously on the
                // calling thread — guaranteeing durability even if the app crashes immediately
                // after the call. Setting true moves writes to a background thread, which
                // reduces main-thread I/O overhead but means breadcrumbs logged just before
                // a crash may not be flushed to disk before the process exits.
                // Choose async mode only when breadcrumb volume is high and performance
                // matters more than capturing the last few entries before a crash.
                WS1Intelligence.setAsyncBreadcrumbMode(newValue)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync vs. Async Trade-off")
                        .font(.headline)
                    Text("**Sync (default):** Each breadcrumb is written to disk before the call returns. This guarantees that even breadcrumbs logged immediately before a crash are persisted and visible in the crash report.\n\n**Async:** Writes are queued to a background thread for better performance. Breadcrumbs logged right before a crash may not be saved if the background write hasn't completed when the process exits.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "Async Mode",
                systemImage: "bolt",
                description: "Control whether breadcrumb disk writes happen synchronously (durable) or on a background thread (faster)."
            )
        }
        .listRowBackground(Color.blue.opacity(0.07))
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            ForEach(Self.quickActionLabels, id: \.self) { label in
                Button {
                    self.leaveBreadcrumb(label)
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(Color.accentColor)
                            .imageScale(.small)
                        Text(label)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }
                }
            }
        } header: {
            SectionHeaderView(
                title: "Quick Actions",
                systemImage: "bolt.fill",
                description: "Pre-built breadcrumbs for common app lifecycle events. Tap any to log it immediately."
            )
        } footer: {
            Text("These breadcrumbs simulate the kind of markers a real app would leave at key navigation and lifecycle points.")
                .font(.caption)
        }
    }

    // MARK: - Session History Section

    private var historySection: some View {
        Section {
            if self.history.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "bookmark.slash")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No breadcrumbs logged yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(self.history.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.text)
                            .font(.subheadline)
                        Text(entry.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            SectionHeaderView(
                title: "Session History",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                description: "Breadcrumbs left during this app session. This list is local only — it is not persisted and resets when the app relaunches."
            )
        } footer: {
            if !self.history.isEmpty {
                Text("\(self.history.count) breadcrumb\(self.history.count == 1 ? "" : "s") logged this session.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Helpers

    /// Calls the SDK to log a breadcrumb, records it in the local session history,
    /// and briefly shows a confirmation toast.
    private func leaveBreadcrumb(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // WS1Intelligence.leaveBreadcrumb(_:)
        // Logs a free-form text string (max 140 chars) timestamped at the moment of the call.
        // Breadcrumbs appear in crash reports and user flow traces to provide context about
        // what the user was doing leading up to a crash or event.
        // If logged while a user flow is active, the SDK automatically associates this
        // breadcrumb with that flow — no additional code is required for the association.
        // If no custom user-flow is active, all breadcrumbs are by default associated with the long running session user-flow.
        // Constraint: strings longer than 140 characters are silently truncated by the SDK.
        WS1Intelligence.leaveBreadcrumb(trimmed)

        self.history.append(BreadcrumbEntry(text: trimmed, timestamp: Date()))
        self.toastMessage = "Breadcrumb logged"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BreadcrumbsView()
            .environment(IntelSDKManager())
    }
}
