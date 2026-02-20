//
//  UserFlowsView+ActiveFlows.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI
import WS1IntelligenceSDK


extension UserFlowsView {

    // MARK: - Section: Active Flows

    @ViewBuilder
    var activeFlowsSection: some View {
        // Render presets in their own section before active flows
        self.startFlowSectionPresets

        let activeFlows = self.flows.filter { $0.status == .running }

        if !activeFlows.isEmpty {
            ForEach(activeFlows) { flow in
                self.activeFlowRow(for: flow)
            }
        }
    }

    // MARK: - Section: Quick-Start Presets

    // Note: presets are rendered inline within the startFlowSection continuation below.
    // They are separated as a dedicated section for visual grouping.
    private var startFlowSectionPresets: some View {
        Section {
            ForEach(Self.presetFlowNames, id: \.self) { name in
                let isActive = self.isFlowActive(name: name)
                Button {
                    self.beginFlow(name: name, timeoutText: "")
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundStyle(isActive ? Color.secondary : Color.accentColor)
                            .imageScale(.small)
                        Text(name)
                            .foregroundStyle(isActive ? .secondary : .primary)
                        Spacer()
                        if isActive {
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12), in: Capsule())
                        } else {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                                .imageScale(.small)
                        }
                    }
                }
                .disabled(isActive)
            }
        } header: {
            SectionHeaderView(
                title: "Quick Start",
                systemImage: "bolt.fill",
                description: "Tap a preset to immediately begin a demo user flow with that name."
            )
        } footer: {
            Text("Preset flows use no timeout. Tap Begin on an active flow row below to End, Fail, or Cancel it.")
                .font(.caption)
        }
    }

    @ViewBuilder
    private func activeFlowRow(for flow: UserFlowEntry) -> some View {
        Section {
            // Header row: name + live timer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flow.name)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(flow.startedAt, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if let timeout = flow.timeout {
                            Text("/ \(Int(timeout))s timeout")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Text("Running")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }
            .padding(.vertical, 4)
            .onAppear {
                if let timeout = flow.timeout {
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                        self.timeoutFlow(flow)
                    }
                }
            }

            // Action buttons: End / Fail / Cancel
            HStack(spacing: 12) {
                Button {
                    self.endFlow(flow)
                } label: {
                    Label("End", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button {
                    self.failFlow(flow)
                } label: {
                    Label("Fail", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button {
                    self.cancelFlow(flow)
                } label: {
                    Label("Cancel", systemImage: "minus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.secondary, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // Inline breadcrumb entry
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Breadcrumbs auto-associate with this flow")
                        .font(.headline)
                    Text("Any breadcrumb logged while this flow is active is automatically attached to it by the SDK — no extra code needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "Add breadcrumb for \"\(flow.name)\"…",
                    text: Binding(
                        get: { self.breadcrumbInputs[flow.id] ?? "" },
                        set: { self.breadcrumbInputs[flow.id] = $0 }
                    )
                )
                .autocorrectionDisabled()

                Button {
                    let text = self.breadcrumbInputs[flow.id] ?? ""
                    self.leaveBreadcrumbForFlow(flow, text: text)
                    self.breadcrumbInputs[flow.id] = ""
                } label: {
                    HStack {
                        Spacer()
                        Label("Leave Breadcrumb", systemImage: "bookmark.fill")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled((self.breadcrumbInputs[flow.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Mini breadcrumb trail
            if !flow.breadcrumbs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Breadcrumbs (\(flow.breadcrumbs.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(flow.breadcrumbs.reversed()) { crumb in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundStyle(.teal)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(crumb.text)
                                    .font(.caption)
                                Text(crumb.timestamp, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

        } header: {
            Text(flow.name)
                .font(.caption.weight(.semibold))
                .textCase(nil)
        }
        .listRowBackground(Color.blue.opacity(0.05))
    }

    /// Returns true if a flow with the given name is currently in `.running` state.
    private func isFlowActive(name: String) -> Bool {
        self.flows.contains { $0.name == name && $0.status == .running }
    }

    /// Leaves a breadcrumb associated with the given flow and records it in the local trail.
    private func leaveBreadcrumbForFlow(_ flow: UserFlowEntry, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // WS1Intelligence.leaveBreadcrumb(_:)
        // Logs a free-form text string (max 140 chars) timestamped at the moment of the call.
        // When called while a user flow is active, the SDK automatically associates this
        // breadcrumb with that flow — no additional code is required. The breadcrumb will
        // appear in the flow's detail view on the portal, providing context about what the
        // user was doing during the flow.
        // Constraint: strings longer than 140 characters are silently truncated by the SDK.
        WS1Intelligence.leaveBreadcrumb(trimmed)

        let crumb = FlowBreadcrumb(text: trimmed, timestamp: Date())
        if let idx = self.flows.firstIndex(where: { $0.id == flow.id }) {
            self.flows[idx].breadcrumbs.append(crumb)
        }
        self.presentToast("Breadcrumb logged for \"\(flow.name)\"")
    }
}

