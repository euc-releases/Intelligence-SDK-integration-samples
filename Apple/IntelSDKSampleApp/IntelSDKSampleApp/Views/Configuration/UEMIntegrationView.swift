//
//  UEMIntegrationView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - Constants

private enum UEMIntegrationConstants {
    static let integrationSnippet = """
    // Before WS1Intelligence.enable():
    WS1Intelligence.setUEMProviderDelegate(self)

    // Intelligence SDK 26.2.0+: WS1UEMDataDelegate includes deviceUUID (UEM global device ID).
    // UEM Application Configuration key: intelsdk_device_uuid (e.g. value {DeviceUuId}).
    // Swift: managedAppConfig[WS1UEMAttributeKeys.intelSDKDeviceUUID()]

    // If you use both WS1SDK (AirWatch) and Intelligence SDK, WS1SDK 26.02.0+ is required.

    // In production,
    // -> read from ManagedAppConfig via NSUserDefaults keyed by WS1UEMAttributeKeys.
    // -> read profiles from Custom UEM SDK settings (if integrated), e.g.:
    // receivedProfiles: (NSArray *) profiles {
    //   AWCustomPayload *custom = profiles.firstObject.customPayload
    //   NSString *settings = custom.settings
    //   WS1Intelligence.setSDKControlConfig(settings)
    // }
    """
}

// MARK: - UEMIntegrationView

/// Displays read-only UEM delegate values (post-init) and a code snippet
/// showing real-world integration with WS1UEMDataDelegate and UEM Custom Settings.
struct UEMIntegrationView: View {

    @Environment(IntelSDKManager.self) private var manager
    @State private var toastMessage: String?
    @State private var usernameInput: String = ""

    var body: some View {
        Form {
            self.sdkUsernameSection
            self.uemDelegateSection
            self.integrationSnippetSection
        }
        .navigationTitle("UEM Integration")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: self.$toastMessage, duration: 2)
    }

    // MARK: - Section: SDK Username (Feature 11)

    private var sdkUsernameSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("Enter username", text: self.$usernameInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Set Username") {
                    self.setUsername()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.usernameInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            SectionHeaderView(
                title: "SDK Username",
                systemImage: "person.crop.circle",
                description: "Sets the username associated with the device UUID for telemetry. Mutable anytime post-init."
            )
        }
    }

    private func setUsername() {
        let username = self.usernameInput.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty else {
            return
        }

        // WS1Intelligence.setUsername(_:)
        // Sets a relationship between the provided username string and the IntelSDK UUID.
        // Used for user identification in crash reports, user flows, and other app level telemetry.
        // Mutable anytime post-init. Call after enable() to associate a user with the device.
        WS1Intelligence.setUsername(username)

        self.toastMessage = "Username set to \(username) ✓"
    }

    // MARK: - Section: UEM Delegate Values (Read-Only)

    private var uemDelegateSection: some View {
        Section {
            self.readOnlyRow(label: "Serial Number", value: self.manager.uemSerialNumber)
            self.readOnlyRow(label: "Device UDID", value: self.manager.uemDeviceUDID)
            self.readOnlyRow(label: "UEM device UUID", value: self.manager.uemDeviceUUID)
            self.readOnlyRow(label: "Username", value: self.manager.uemUsername)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .padding(.top, 2)
                Text("WS1UEMDataDelegate must be set before SDK initialization. These values were configured on the Dashboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "UEM Delegate Values",
                systemImage: "building.2",
                description: "Device attributes published to the Intelligence backend for device identity enrichment."
            )
        }
    }

    // MARK: - Section: Integration Code Snippet

    private var integrationSnippetSection: some View {
        Section {
            CodeSnippetView(
                code: UEMIntegrationConstants.integrationSnippet,
                label: "SDK call"
            )
        } header: {
            SectionHeaderView(
                title: "Real-World Integration",
                systemImage: "chevron.left.forwardslash.chevron.right",
                description: "Set the delegate before enable(); in UEM-managed apps, read attributes from ManagedAppConfig."
            )
        }
    }

    // MARK: - Helpers

    private func readOnlyRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UEMIntegrationView()
            .environment(IntelSDKManager())
    }
}
