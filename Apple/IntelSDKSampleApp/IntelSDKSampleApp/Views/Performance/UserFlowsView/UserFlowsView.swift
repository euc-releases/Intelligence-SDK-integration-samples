//
//  UserFlowsView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - Supporting Types

/// The terminal state a user flow can reach after it has been started.
enum UserFlowStatus: String {
    case running   = "Running"
    case ended     = "Ended"
    case failed    = "Failed"
    case cancelled = "Cancelled"
    // TODO: need to add timeout

    var systemImage: String {
        switch self {
        case .running:   return "arrow.trianglehead.2.clockwise.rotate.90"
        case .ended:     return "checkmark.circle.fill"
        case .failed:    return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .running:   return .blue
        case .ended:     return .green
        case .failed:    return .orange
        case .cancelled: return .secondary
        }
    }
}

/// A single breadcrumb recorded against a specific user flow during this session.
/// Local tracking only — not persisted to disk.
struct FlowBreadcrumb: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
}

/// A user flow entry tracked locally in the current session.
struct UserFlowEntry: Identifiable {
    let id = UUID()
    let name: String
    var status: UserFlowStatus
    let startedAt: Date
    let timeout: Double?
    var breadcrumbs: [FlowBreadcrumb] = []
    var completedAt: Date?

    /// Elapsed time from when the flow was started to when it completed (or now if still running).
    var elapsedAtCompletion: TimeInterval? {
        guard let completedAt = self.completedAt else { return nil }
        return completedAt.timeIntervalSince(self.startedAt)
    }
}

// MARK: - UserFlowsView

/// Demonstrates the WS1 Intelligence SDK user flow tracking APIs.
///
/// User flows allow you to measure key interactions in your app — such as login,
/// account registration, or data sync — from start to finish. The SDK tracks each
/// named flow's duration and outcome (ended, failed, cancelled, crashed, or timed out)
/// and surfaces the results on the Omnissa Intelligence portal.
///
/// This view exposes:
/// - A custom name + optional timeout form to begin any named flow
/// - Preset quick-start flows for common scenarios
/// - Live control rows for each active flow (End / Fail / Cancel) with an elapsed timer
/// - Inline breadcrumb entry per flow — the SDK auto-associates breadcrumbs with the active flow
/// - A session history of all completed flows with status and duration
struct UserFlowsView: View {

    @Environment(IntelSDKManager.self) private var manager

    // MARK: Start-a-flow inputs
    @State private var customFlowName: String = ""
    @State private var timeoutText: String = ""

    // MARK: Inline breadcrumb state keyed by flow ID
    @State var breadcrumbInputs: [UUID: String] = [:]

    // MARK: All flows tracked this session
    @State var flows: [UserFlowEntry] = []

    // MARK: Toast state
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    static let presetFlowNames: [String] = [
        "Login Flow",
        "Checkout Flow",
        "Data Sync"
    ]

    // MARK: - Body

    var body: some View {
        Form {
            self.behavioralInfoSection
            self.startFlowSection
            self.activeFlowsSection
            self.historySection
        }
        .navigationTitle("User Flows")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let completedFlows = self.flows.filter { $0.status != .running }
                if !completedFlows.isEmpty {
                    Button("Clear History") {
                        self.flows.removeAll { $0.status != .running }
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if self.showToast {
                Text(self.toastMessage)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: self.showToast)
    }

    // MARK: - Section: Behavioral Info Callouts

    private var behavioralInfoSection: some View {
        Section {
            self.infoRow(
                icon: "timer",
                color: .blue,
                title: "Automatic App Load Time",
                body: "App load time is automatically tracked as a user flow by the SDK. You do not need to begin or end it yourself."
            )

            self.infoRow(
                icon: "exclamationmark.triangle.fill",
                color: .red,
                title: "Crash Behavior",
                body: "If a crash occurs, all in-progress user flows are automatically marked as crashed and reported with the crash."
            )

            self.infoRow(
                icon: "arrow.trianglehead.2.clockwise.rotate.90",
                color: .orange,
                title: "One Flow Per Name",
                body: "Only one user flow per name can be active at a time. Beginning a flow with an already-active name cancels the first one."
            )

            self.infoRow(
                icon: "minus.circle",
                color: .secondary,
                title: "Cancelled Flows Are Not Reported",
                body: "Cancelled user flows are treated as if they never existed — they do not appear on the Omnissa Intelligence portal."
            )
        } header: {
            SectionHeaderView(
                title: "How User Flows Work",
                systemImage: "info.circle",
                description: "Key behaviors to understand before using the user flow APIs."
            )
        }
        .listRowBackground(Color.blue.opacity(0.07))
    }

    // MARK: - Section: Start a Flow

    private var startFlowSection: some View {
        Section {
            TextField("Flow name (e.g. \"Login\")", text: self.$customFlowName)
                .autocorrectionDisabled()

            HStack {
                Text("Timeout (seconds)")
                Spacer()
                TextField("Optional", text: self.$timeoutText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            Button {
                self.beginFlow(name: self.customFlowName, timeoutText: self.timeoutText)
                self.customFlowName = ""
                self.timeoutText = ""
            } label: {
                HStack {
                    Spacer()
                    Label("Begin Flow", systemImage: "play.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(self.customFlowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            self.codeSnippetView("""
                // Without timeout
                WS1Intelligence.beginUserFlow("Login")

                // With timeout (seconds) — flow is marked timed out if not completed in time
                WS1Intelligence.beginUserFlow("Login", timeout: 30)
                """)

        } header: {
            SectionHeaderView(
                title: "Start a Flow",
                systemImage: "play.circle",
                description: "Begin a named user flow. Supply an optional timeout in seconds — if the flow is not ended, failed, or cancelled before the timeout elapses, the SDK marks it as timed out."
            )
        } footer: {
            Text("Flow names are case-sensitive. Use consistent names across your codebase to correctly aggregate data on the portal.")
                .font(.caption)
        }
    }

    // MARK: - Section: Session History

    private var historySection: some View {
        let completedFlows = self.flows.filter { $0.status != .running }

        return Section {
            if completedFlows.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No completed flows yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(completedFlows.reversed()) { flow in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: flow.status.systemImage)
                            .foregroundStyle(flow.status.color)
                            .font(.subheadline)
                            .frame(width: 20)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(flow.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(flow.status.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(flow.status.color.opacity(0.12), in: Capsule())
                            }
                            Text(flow.name)
                                .font(.subheadline)
                            HStack(spacing: 8) {
                                if let elapsed = flow.elapsedAtCompletion {
                                    Text(String(format: "%.2fs", elapsed))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                if let completedAt = flow.completedAt {
                                    Text(completedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if !flow.breadcrumbs.isEmpty {
                                    Text("\(flow.breadcrumbs.count) breadcrumb\(flow.breadcrumbs.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            SectionHeaderView(
                title: "Session History",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                description: "All user flows completed during this session. Local only — resets on app relaunch."
            )
        } footer: {
            if !completedFlows.isEmpty {
                Text("\(completedFlows.count) flow\(completedFlows.count == 1 ? "" : "s") completed this session.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Private Helpers

    /// Shows a bottom toast message for 1.5 seconds.
    func presentToast(_ message: String) {
        self.toastMessage = message
        self.showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showToast = false
        }
    }

    /// A monospaced code snippet block used inline within sections to illustrate SDK API calls.
    @ViewBuilder
    private func codeSnippetView(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("SDK calls")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(code)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    /// A reusable info row with icon, title, and body text.
    @ViewBuilder
    private func infoRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserFlowsView()
            .environment(IntelSDKManager())
    }
}
