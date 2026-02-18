//
//  TelemetryView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// Top-level container for the Telemetry tab.
///
/// Hosts DEX Opt-In, Privacy Configuration, and Telemetry Export sub-features
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct TelemetryView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {

                SDKFeatureComingSoonView(
                    featureName: "Telemetry",
                    featureDescription: "DEX opt-in controls, privacy configuration, and telemetry data export.",
                    systemImage: "antenna.radiowaves.left.and.right"
                )
                .navigationTitle("Telemetry")
            } else {
                SDKNotInitializedView()
                    .navigationTitle("Telemetry")
            }
        }
    }
}

#Preview {
    TelemetryView()
        .environment(IntelSDKManager())
}
