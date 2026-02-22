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
                List {
                    Section {
                        NavigationLink {
                            DEXOptInView()
                        } label: {
                            Label("DEX Opt-In", systemImage: "hand.raised")
                        }

                        NavigationLink {
                            PrivacyConfigView()
                        } label: {
                            Label("Privacy Configuration", systemImage: "lock.shield")
                        }

                        NavigationLink {
                            SDKFeatureComingSoonView(
                                featureName: "Telemetry Export",
                                featureDescription: "Export telemetry data by type, format, and category.",
                                systemImage: "square.and.arrow.up"
                            )
                        } label: {
                            Label("Telemetry Export", systemImage: "square.and.arrow.up")
                        }
                    } header: {
                        SectionHeaderView(
                            title: "Telemetry Features",
                            systemImage: "antenna.radiowaves.left.and.right",
                            description: "DEX opt-in controls, privacy configuration, and telemetry data export."
                        )
                    }
                }
                .listStyle(.insetGrouped)
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
