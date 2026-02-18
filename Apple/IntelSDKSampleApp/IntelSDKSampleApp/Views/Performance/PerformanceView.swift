//
//  PerformanceView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// Top-level container for the Performance tab.
///
/// Hosts the User Flows and Network Insights sub-features
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct PerformanceView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {

                SDKFeatureComingSoonView(
                    featureName: "Performance",
                    featureDescription: "User flow tracking and network request monitoring (APM).",
                    systemImage: "chart.xyaxis.line"
                )
                .navigationTitle("Performance")
            } else {
                SDKNotInitializedView()
                    .navigationTitle("Performance")
            }
        }
    }
}

#Preview {
    PerformanceView()
        .environment(IntelSDKManager())
}
