//
//  DashboardView+PreInitView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI
import CoreLocation


extension DashboardView {

    // MARK: App ID Section

    var appIDSection: some View {
        Section {
            // Bind both the manager property and @AppStorage so the value persists.
            TextField("YOUR_APP_ID_HERE", text: Binding(
                get: { self.manager.appID },
                set: { self.manager.appID = $0; self.savedAppID = $0 }
            ))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Link(destination: URL(string: "https://docs.omnissa.com/bundle/Intelligence/page/IntelIntelligenceSDKApps.html")!) {
                Label("How to find your App ID", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
        } header: {
            SectionHeaderView(
                title: "App ID",
                systemImage: "key.horizontal",
                description: "Your Omnissa Intelligence App ID. Never hardcoded — enter at runtime only."
            )
        } footer: {
            Text("Find or create your App ID in the Intelligence portal under Unified Endpoint Management -> Apps → IntelligenceSDK Apps.")
                .font(.caption)
        }
    }

    // MARK: Network Monitoring Section

    var networkMonitoringSection: some View {
        @Bindable var mgr = self.manager
        return Section {
            Toggle(isOn: $mgr.enableServiceMonitoring) {
                Label("Enable Service Monitoring", systemImage: "network")
            }
            .onChange(of: self.manager.enableServiceMonitoring) { _, newValue in
                if !newValue {
                    // When the master switch is off, sub-options become irrelevant.
                    self.manager.monitorNSURLSession = false
                    self.manager.monitorNSURLConnection = false
                    self.manager.monitorWKWebView = false
                }
            }

            Toggle(isOn: $mgr.monitorNSURLSession) {
                Label("Monitor NSURLSession", systemImage: "arrow.up.arrow.down")
            }
            .disabled(!self.manager.enableServiceMonitoring)

            Toggle(isOn: $mgr.monitorNSURLConnection) {
                Label("Monitor NSURLConnection", systemImage: "arrow.up.arrow.down.circle")
            }
            .disabled(!self.manager.enableServiceMonitoring)

            Toggle(isOn: $mgr.monitorWKWebView) {
                Label("Monitor WKWebView", systemImage: "globe")
            }
            .disabled(!self.manager.enableServiceMonitoring)

        } header: {
            SectionHeaderView(
                title: "Network Monitoring",
                systemImage: "antenna.radiowaves.left.and.right",
                description: "Controls which network APIs the SDK automatically intercepts for APM data."
            )
        } footer: {
            Text("WKWebView monitoring is off by default because enabling it triggers WKWebView class initialization as a side effect, even in apps that never display web content.")
                .font(.caption)
        }
    }

    // MARK: Data & Crash Config Section

    var dataCrashConfigSection: some View {
        @Bindable var mgr = self.manager
        return Section {
            Toggle(isOn: $mgr.allowsCellularAccess) {
                Label("Allow Cellular Upload", systemImage: "cellularbars")
            }

            Toggle(isOn: $mgr.enableMachExceptionHandling) {
                Label("MACH Exception Handling", systemImage: "exclamationmark.octagon")
            }

        } header: {
            SectionHeaderView(
                title: "Data & Crash Config",
                systemImage: "shield.lefthalf.filled",
                description: "Controls cellular data usage and MACH-level crash capture."
            )
        } footer: {
            Text("MACH exception handling captures additional crash classes (e.g. stack overflows). Disable if another crash SDK already owns MACH exceptions. Has no effect when a debugger is attached.")
                .font(.caption)
        }
    }

    // MARK: DEX Entitlements Section

    var dexEntitlementsSection: some View {
        Section {
            EntitlementRow(
                label: "Bluetooth",
                systemImage: "b.circle",
                isOn: Binding(
                    get: { self.manager.selectedEntitlementKeys.contains("bluetooth") },
                    set: { if $0 { self.manager.selectedEntitlementKeys.insert("bluetooth") } else { self.manager.selectedEntitlementKeys.remove("bluetooth") } }
                )
            )
            EntitlementRow(
                label: "Wi-Fi Info",
                systemImage: "wifi",
                isOn: Binding(
                    get: { self.manager.selectedEntitlementKeys.contains("wifi_info") },
                    set: { if $0 { self.manager.selectedEntitlementKeys.insert("wifi_info") } else { self.manager.selectedEntitlementKeys.remove("wifi_info") } }
                )
            )
            if self.manager.selectedEntitlementKeys.contains("wifi_info") {
                self.locationPermissionRow
            }
            EntitlementRow(
                label: "Multicast",
                systemImage: "dot.radiowaves.left.and.right",
                isOn: Binding(
                    get: { self.manager.selectedEntitlementKeys.contains("multicast") },
                    set: { if $0 { self.manager.selectedEntitlementKeys.insert("multicast") } else { self.manager.selectedEntitlementKeys.remove("multicast") } }
                )
            )
        } header: {
            SectionHeaderView(
                title: "DEX Entitlements",
                systemImage: "checkmark.seal",
                description: "Declares app entitlements that unlock additional DEX telemetry data sources."
            )
        } footer: {
            Text("Select only the entitlements your app binary actually declares in its provisioning profile. The SDK does not verify them — declaring an entitlement you do not hold will silently produce no extra data.")
                .font(.caption)
        }
    }

    // MARK: Location Permission Row (Wi-Fi Info)

    @ViewBuilder
    private var locationPermissionRow: some View {
        // SSID and BSSID collection via NEHotspotNetwork requires the app to hold
        // When In Use location authorization. Without it the OS returns nil for
        // both values even if the wifi_info entitlement is declared and DEX is opted in.
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.circle")
                .foregroundStyle(.orange)
                .font(.subheadline)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 6) {
                Text("Location Permission Required for Wi-Fi Info")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("SSID and BSSID collection requires When In Use location authorization. A future feature may need Always On authorization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                self.locationPermissionButton
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.orange.opacity(0.06))
    }

    @ViewBuilder
    private var locationPermissionButton: some View {
        switch self.locationHelper.authorizationStatus {
        case .notDetermined:
            Button {
                self.locationHelper.requestWhenInUse()
            } label: {
                Label("Request Location Permission", systemImage: "location.circle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case .authorizedWhenInUse, .authorizedAlways:
            Label("Location Authorized", systemImage: "location.fill")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.green)

        case .denied, .restricted:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings to Grant Access", systemImage: "gear")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)

        @unknown default:
            EmptyView()
        }
    }

    // MARK: UEM Delegate Section

    var uemDelegateSection: some View {
        @Bindable var mgr = self.manager
        return Section {
            LabeledContent("Serial Number") {
                TextField("Optional", text: $mgr.uemSerialNumber)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            LabeledContent("Device UDID") {
                TextField("Optional", text: $mgr.uemDeviceUDID)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            LabeledContent("Username") {
                TextField("Optional", text: $mgr.uemUsername)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        } header: {
            SectionHeaderView(
                title: "UEM Delegate",
                systemImage: "building.2",
                description: "Publish UEM device attributes to the Intelligence backend for device identity enrichment."
            )
        } footer: {
            Text("In a UEM-managed deployment, these values come from NSUserDefaults ManagedAppConfig keys. The delegate MUST be set before enabling the SDK — it cannot be changed after initialization.")
                .font(.caption)
        }
    }

    // MARK: Enable SDK Section

    var enableSection: some View {
        Section {
            Button {
                self.handleEnableSDK()
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "bolt.fill")
                    Text("Enable SDK")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .font(.headline)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } footer: {
            if let errorMessage = self.enableErrorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                Text("Once enabled, WS1Config is frozen for this app session. Restart the app to change initialization settings.")
                    .font(.caption)
            }
        }
        .alert("App ID Required", isPresented: self.$showEmptyAppIDAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter your Omnissa Intelligence App ID before enabling the SDK.")
        }
    }

    // MARK: - Actions

    private func handleEnableSDK() {
        self.enableErrorMessage = nil
        let result = self.manager.enableSDK()
        if let errorMsg = result {
            self.enableErrorMessage = errorMsg
            self.showEmptyAppIDAlert = true
        } else {
            withAnimation {
                self.showSuccessBanner = true
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    self.showSuccessBanner = false
                }
            }
        }
    }

}


/// A checkmark-style row for toggling a single entitlement on or off.
///
/// Uses a plain `Bool` binding rather than `Set<WS1Entitlement>` because
/// `WS1Entitlement` factory methods return a new `NSObject` instance on every call.
/// Pointer-based `Set` equality would make `contains` always return false, breaking
/// the selection state. The parent view manages the underlying `Set<String>` keys.
private struct EntitlementRow: View {
    let label: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            self.isOn.toggle()
        } label: {
            HStack {
                Label(self.label, systemImage: self.systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                if self.isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
