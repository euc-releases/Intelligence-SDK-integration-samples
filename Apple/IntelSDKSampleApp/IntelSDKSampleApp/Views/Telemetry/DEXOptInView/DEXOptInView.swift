//
//  DEXOptInView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - DEXOptInView

/// Demonstrates the WS1 Intelligence SDK DEX Telemetry and Opt-In feature.
///
/// Provides per-type opt-in toggles for Application, DEX, ZeroTrust, and AllAdvancedTelemetry.
/// Displays read-only entitlements configured before SDK init and info callouts for DEX enablement,
/// location data requirements, and battery monitoring.
struct DEXOptInView: View {
    @Environment(IntelSDKManager.self) private var manager

    // MARK: - Toast State

    @State private var toastMessage: String?

    // MARK: - Opt-In State (mirrors SDK; refreshed on appear and after each toggle)

    @State private var applicationOptIn: Bool = true
    @State private var dexOptIn: Bool = false
    @State private var zeroTrustOptIn: Bool = false
    @State private var allAdvancedOptIn: Bool = false

    // MARK: - Body

    var body: some View {
        Form {
            self.entitlementsSection
            self.optInTogglesSection
            self.dexEnablementSection
            self.locationDataSection
            self.batteryMonitoringSection
        }
        .navigationTitle("DEX Opt-In")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: self.$toastMessage, duration: 2)
        .onAppear {
            self.refreshOptInState()
        }
    }

    // MARK: - Section: Entitlements (Pre-Init, Read-Only)

    private var entitlementsSection: some View {
        Section {
            self.lockedToggleRow(
                label: "Bluetooth",
                icon: "b.circle",
                value: self.manager.selectedEntitlementKeys.contains("bluetooth")
            )
            self.lockedToggleRow(
                label: "Wi-Fi Info",
                icon: "wifi",
                value: self.manager.selectedEntitlementKeys.contains("wifi_info")
            )
            self.lockedToggleRow(
                label: "Multicast",
                icon: "dot.radiowaves.left.and.right",
                value: self.manager.selectedEntitlementKeys.contains("multicast")
            )

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .padding(.top, 2)
                Text("Entitlements are part of WS1Config and were set before SDK init.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "DEX Entitlements",
                systemImage: "checkmark.seal",
                description: "System entitlements that unlock additional DEX telemetry data sources."
            )
        }
    }

    // MARK: - Section: Opt-In Toggles (Post-Init, Mutable)

    private var optInTogglesSection: some View {
        Section {
            self.optInToggleRow(
                type: .application,
                isOn: self.$applicationOptIn,
                label: "Application",
                icon: "app.badge",
                description: "Enables sending application telemetry to the Intelligence backend. Default: ON."
            )
            self.optInToggleRow(
                type: .DEX,
                isOn: self.$dexOptIn,
                label: "DEX",
                icon: "cpu",
                description: "Device telemetry. Default: OFF."
            )
            self.optInToggleRow(
                type: .zeroTrust,
                isOn: self.$zeroTrustOptIn,
                label: "ZeroTrust",
                icon: "shield.checkered",
                description: "Zero Trust telemetry. Does not send to Intelligence backend. Default: OFF."
            )
            self.optInToggleRow(
                type: .allAdvancedTelemetry,
                isOn: self.$allAdvancedOptIn,
                label: "All Advanced Telemetry",
                icon: "square.stack.3d.up",
                description: "Enables both DEX and ZeroTrust. Disabling turns off both."
            )

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                    .padding(.top, 2)
                Text("Disabling one Advanced Telemetry feature (DEX or ZeroTrust) turns off all other opted-in advanced features.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "Telemetry Opt-In",
                systemImage: "hand.raised",
                description: "Control which telemetry types are collected and reported."
            )
        }
    }

    // MARK: - Section: DEX Enablement Info

    private var dexEnablementSection: some View {
        Section {
            InfoRowView(
                icon: "info.circle.fill",
                color: .blue,
                title: "DEX Enablement",
                infoBody: "DEX is disabled by default. If the WS1 UEM SDK is integrated with your app, DEX can be enabled or disabled remotely from the UEM console via the custom SDK setting CaptureDEXData. If the UEM SDK is not integrated, it is the app's responsibility to enable or disable DEX directly using the opt-in API."
            )
        }
    }

    // MARK: - Section: Location Data

    private var locationDataSection: some View {
        Section {
            InfoRowView(
                icon: "location.circle.fill",
                color: .teal,
                title: "Location Data",
                infoBody: "DEX can request location_longitude and location_latitude only when DEX is enabled. The app must have entitlements and the user must grant location permission; the SDK does not trigger the request. DEX requests location once every 5 minutes when permissions allow; each result is cached for up to 5 minutes. DEX stops requesting in background and resumes in foreground."
            )
        } header: {
            SectionHeaderView(
                title: "Location Requirements",
                systemImage: "location",
                description: "Location data collection requirements and limitations."
            )
        }
    }

    // MARK: - Section: Battery Monitoring

    private var batteryMonitoringSection: some View {
        Section {
            InfoRowView(
                icon: "battery.100",
                color: .green,
                title: "Battery Monitoring",
                infoBody: "When DEX opt-in is set to true, the SDK sets UIDevice.isBatteryMonitoringEnabled = true to report battery metrics. Your app should not set this property back to false after opting in."
            )
        } header: {
            SectionHeaderView(
                title: "Battery Note",
                systemImage: "battery.100",
                description: "SDK behavior when DEX is enabled."
            )
        }
    }

    // MARK: - Opt-In Toggle Row

    @ViewBuilder
    private func optInToggleRow(type: WS1TelemetryType, isOn: Binding<Bool>, label: String, icon: String, description: String) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                self.setOptInStatus(for: type, value: newValue)
                self.refreshOptInState()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text(label)
                }
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - SDK Interactions

    /// Refreshes local opt-in state from the SDK. Call on appear and after each toggle.
    private func refreshOptInState() {
        self.applicationOptIn = WS1Intelligence.getOptInStatus(for: .application)
        self.dexOptIn = WS1Intelligence.getOptInStatus(for: .DEX)
        self.zeroTrustOptIn = WS1Intelligence.getOptInStatus(for: .zeroTrust)
        self.allAdvancedOptIn = WS1Intelligence.getOptInStatus(for: .allAdvancedTelemetry)
    }

    /// Sets the opt-in status for the given telemetry type and shows toast feedback.
    private func setOptInStatus(for type: WS1TelemetryType, value: Bool) {
        // WS1Intelligence.setOptInStatusFor(type:andStatus:)
        // Sets the opt-in status for telemetry instrumentation. Setting to YES enables
        // collection of telemetry data for that type. Application default is YES; DEX and
        // ZeroTrust default is NO. AllAdvancedTelemetry enables both DEX and ZeroTrust;
        // disabling it turns off both. Disable features before enabling them again if needed.
        // Mutable anytime after enable() — no restart required.
        WS1Intelligence.setOptInStatusFor(type, andStatus: value)

        let typeLabel = self.label(for: type)
        let statusLabel = value ? "enabled" : "disabled"
        self.toastMessage = "\(typeLabel) \(statusLabel) ✓"
    }

    /// Human-readable label for telemetry type.
    private func label(for type: WS1TelemetryType) -> String {
        switch type {
        case .application: return "Application"
        case .DEX: return "DEX"
        case .zeroTrust: return "ZeroTrust"
        case .allAdvancedTelemetry: return "All Advanced Telemetry"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Reusable Sub-Views

    /// A toggle-style row that always appears locked (non-interactive), reflecting a pre-init frozen config value.
    @ViewBuilder
    private func lockedToggleRow(label: String, icon: String, value: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(label)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(value ? .green : .red)
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DEXOptInView()
            .environment(IntelSDKManager())
    }
}
