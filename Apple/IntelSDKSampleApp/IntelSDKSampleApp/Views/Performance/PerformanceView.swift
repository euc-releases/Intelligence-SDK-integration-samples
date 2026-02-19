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
/// Acts as a navigation hub for the two Performance sub-features:
/// User Flows and Network Insights (APM).
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct PerformanceView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {
                List {
                    Section {
                        NavigationLink {
                            UserFlowsView()
                        } label: {
                            Label("User Flows", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        }

                        NavigationLink(destination: {
                            SDKFeatureComingSoonView(
                                featureName: "Network Insights",
                                featureDescription: "Automatic and manual network request monitoring (APM).",
                                systemImage: "network"
                            )
                            .navigationTitle("Network Insights")
                            .navigationBarTitleDisplayMode(.inline)
                        }, label: {
                            Label("Network Insights", systemImage: "network")
                        })
                    } header: {
                        SectionHeaderView(
                            title: "Performance Features",
                            systemImage: "chart.xyaxis.line",
                            description: "User flow tracking and network request monitoring (APM)."
                        )
                    }
                }
                .listStyle(.insetGrouped)
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
