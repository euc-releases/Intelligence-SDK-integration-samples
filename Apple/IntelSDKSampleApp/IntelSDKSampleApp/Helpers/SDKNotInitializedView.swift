//
//  SDKNotInitializedView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// Shown on any feature tab when the SDK has not yet been initialized.
///
/// Guides the user back to the Dashboard to complete the two-phase initialization flow
/// before any SDK feature can be exercised.
struct SDKNotInitializedView: View {

    var body: some View {
        ContentUnavailableView {
            Label("SDK Not Initialized", systemImage: "lock.circle")
        } description: {
            Text("Enable the WS1 Intelligence SDK on the Dashboard tab before using this feature.")
        } actions: {
            // No programmatic tab switching needed — the label is sufficient guidance.
            // Tab selection could be wired via a shared selection binding in a future iteration.
        }
    }
}

/// Shown inside a feature tab that is initialized but not yet implemented in this release.
/// Replaced by the real feature view in its corresponding feature sprint.
struct SDKFeatureComingSoonView: View {

    let featureName: String
    let featureDescription: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(self.featureName, systemImage: self.systemImage)
        } description: {
            Text(self.featureDescription)
                .padding(.bottom, 4)
            Text("This section will be implemented in a future feature sprint.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

#Preview("Not Initialized") {
    SDKNotInitializedView()
}

#Preview("Coming Soon") {
    SDKFeatureComingSoonView(
        featureName: "Diagnostics",
        featureDescription: "Crash reporting, breadcrumbs, and error & exception logging.",
        systemImage: "cross.case"
    )
}
