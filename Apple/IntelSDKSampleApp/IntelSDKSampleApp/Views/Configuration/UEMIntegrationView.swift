//
//  UEMIntegrationView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

// MARK: - Constants

private enum UEMIntegrationConstants {
    static let integrationSnippet = """
    // Before WS1Intelligence.enable():
    WS1Intelligence.setUEMProviderDelegate(self)

    // In production, 
    // -> read from ManagedAppConfig via UEM SDK NSUserDefaults keyed by WS1UEMAttributeKeys.
    // -> read the profiles from Custom UEM SDK settings (if integrated) like below - 
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

    var body: some View {
        Form {
            self.uemDelegateSection
            self.integrationSnippetSection
        }
        .navigationTitle("UEM Integration")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section: UEM Delegate Values (Read-Only)

    private var uemDelegateSection: some View {
        Section {
            self.readOnlyRow(label: "Serial Number", value: self.manager.uemSerialNumber)
            self.readOnlyRow(label: "Device UDID", value: self.manager.uemDeviceUDID)
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
