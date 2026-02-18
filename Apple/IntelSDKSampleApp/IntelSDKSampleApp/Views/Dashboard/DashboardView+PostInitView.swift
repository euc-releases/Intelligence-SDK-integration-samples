//
//  DashboardView+PostInitView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//



import SwiftUI
import WS1IntelligenceSDK


extension DashboardView {

    // MARK: Opt-In Callout

    var optInCalloutSection: some View {
        Section {
            // No telemetry type is opted-in by default after enable().
            // Application, DEX, and ZeroTrust data collection each require an
            // explicit opt-in via setOptInStatus(for:andStatus:) before any
            // data is sent to the Intelligence backend.
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Telemetry Opt-In Required")
                        .font(.headline)
                    Text("Enabling the SDK starts the runtime but does not collect or upload any telemetry. Application, DEX, and ZeroTrust data collection each require an explicit opt-in. Configure opt-in status in the **Telemetry** tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.blue.opacity(0.07))
    }

    // MARK: Frozen Config Banner

    var frozenConfigBannerSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration Frozen")
                        .font(.headline)
                    Text("WS1Config is immutable after SDK initialization. Restart the app to change initialization settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.orange.opacity(0.08))
    }

    // MARK: SDK Status Section

    var sdkStatusSection: some View {
        Section {
            // SDK Running status
            LabeledContent("Status") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Running")
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
            }

            // Device UUID with copy button
            LabeledContent("SDK User UUID") {
                HStack(spacing: 8) {
                    Text(self.manager.userUUID.isEmpty ? "Unavailable" : self.manager.userUUID)
                        .font(.caption.monospaced())
                        .foregroundStyle(self.manager.userUUID.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if !self.manager.userUUID.isEmpty {
                        Button {
                            UIPasteboard.general.string = self.manager.userUUID
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            // App ID (read-only)
            LabeledContent("App ID") {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(self.manager.appID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Crash on last load indicator
            LabeledContent("Last Session") {
                if self.manager.crashedOnLastLoad {
                    Text("Crashed")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                } else {
                    Text("Clean Exit")
                        .foregroundStyle(.green)
                        .font(.subheadline)

                }
            }
        } header: {
            SectionHeaderView(
                title: "SDK Status",
                systemImage: "gauge.medium",
                description: "Current runtime state of the WS1 Intelligence SDK."
            )
        }
    }

    // MARK: Frozen Config Summary

    var frozenConfigSummarySection: some View {
        Section {
            ReadOnlyToggleRow(label: "Service Monitoring", value: self.manager.enableServiceMonitoring)
            ReadOnlyToggleRow(label: "Monitor NSURLSession", value: self.manager.monitorNSURLSession)
            ReadOnlyToggleRow(label: "Monitor NSURLConnection", value: self.manager.monitorNSURLConnection)
            ReadOnlyToggleRow(label: "Monitor WKWebView", value: self.manager.monitorWKWebView)
            ReadOnlyToggleRow(label: "Allow Cellular Upload", value: self.manager.allowsCellularAccess)
            ReadOnlyToggleRow(label: "MACH Exception Handling", value: self.manager.enableMachExceptionHandling)

            LabeledContent("Entitlements") {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(self.manager.selectedEntitlementKeys.isEmpty
                         ? "None"
                         : self.manager.selectedEntitlementKeys
                             .sorted()
                             .map { key -> String in
                                 switch key {
                                 case "bluetooth": return "Bluetooth"
                                 case "wifi_info": return "Wi-Fi Info"
                                 case "multicast": return "Multicast"
                                 default: return key
                                 }
                             }
                             .joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        } header: {
            SectionHeaderView(
                title: "Initialization Config",
                systemImage: "doc.badge.clock",
                description: "WS1Config values that were applied at SDK initialization. Read-only."
            )
        }
    }

    // MARK: Logging Level Section (mutable post-init)

    var loggingLevelSection: some View {
        @Bindable var mgr = self.manager
        return Section {
            Picker("Logging Level", selection: $mgr.loggingLevel) {
                Text("Silent").tag(WS1IntelligenceLoggingLevel.silent)
                Text("Error").tag(WS1IntelligenceLoggingLevel.error)
                Text("Warning").tag(WS1IntelligenceLoggingLevel.warning)
                Text("Info").tag(WS1IntelligenceLoggingLevel.info)
                Text("Debug").tag(WS1IntelligenceLoggingLevel.debug)
            }
            .onChange(of: self.manager.loggingLevel) { _, _ in
                self.manager.applyLoggingLevel()
            }
        } header: {
            SectionHeaderView(
                title: "Logging",
                systemImage: "text.alignleft",
                description: "Controls SDK log verbosity in the Xcode console. Can be changed at any time."
            )
        } footer: {
            Text("Use Debug during development. Set to Warning or Silent for production builds.")
                .font(.caption)
        }
    }
}


// MARK: - Supporting Views

/// A single read-only row displaying a boolean config value with a lock icon.
private struct ReadOnlyToggleRow: View {
    let label: String
    let value: Bool

    var body: some View {
        LabeledContent(self.label) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(self.value ? "On" : "Off")
                    .foregroundStyle(self.value ? .primary : .secondary)
                    .fontWeight(self.value ? .medium : .regular)
            }
        }
    }
}

