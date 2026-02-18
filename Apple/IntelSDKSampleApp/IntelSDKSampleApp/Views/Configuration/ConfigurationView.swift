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
/// Hosts UEM Integration, Custom Settings, and Logging & Utility Settings sub-features
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct ConfigurationView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {

                SDKFeatureComingSoonView(
                    featureName: "Configuration",
                    featureDescription: "UEM integration, custom SDK settings, and logging utility controls.",
                    systemImage: "gearshape.2"
                )
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
