//
//  DiagnosticsView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// Top-level container for the Diagnostics tab.
///
/// Hosts the Crash Reporting, Breadcrumbs, and Error Logging sub-features
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct DiagnosticsView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {

                SDKFeatureComingSoonView(
                    featureName: "Diagnostics",
                    featureDescription: "Crash reporting, breadcrumbs, and error & exception logging.",
                    systemImage: "cross.case"
                )
                .navigationTitle("Diagnostics")
            } else {
                SDKNotInitializedView()
                    .navigationTitle("Diagnostics")
            }
        }
    }
}

#Preview {
    DiagnosticsView()
        .environment(IntelSDKManager())
}
