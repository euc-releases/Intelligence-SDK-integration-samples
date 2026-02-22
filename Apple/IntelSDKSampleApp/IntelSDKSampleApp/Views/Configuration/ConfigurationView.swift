//
//  ConfigurationView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// Top-level container for the Configuration tab.
///
/// Hosts UEM Integration and Custom Settings sub-features.
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct ConfigurationView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {
                List {
                    Section {
                        NavigationLink {
                            UEMIntegrationView()
                        } label: {
                            Label("UEM Integration", systemImage: "building.2")
                        }

                        NavigationLink {
                            CustomSettingsView()
                        } label: {
                            Label("Custom Settings", systemImage: "slider.horizontal.3")
                        }
                    } header: {
                        SectionHeaderView(
                            title: "Configuration",
                            systemImage: "gearshape.2",
                            description: "UEM delegate values, custom SDK settings, and allowed apps."
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Configuration")
            } else {
                SDKNotInitializedView()
                    .navigationTitle("Configuration")
            }
        }
    }
}

#Preview {
    ConfigurationView()
        .environment(IntelSDKManager())
}
