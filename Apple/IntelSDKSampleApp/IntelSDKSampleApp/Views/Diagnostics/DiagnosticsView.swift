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
/// Acts as a navigation hub for the three Diagnostics sub-features:
/// Crash Reporting, Breadcrumbs, and Error & Exception Logging.
/// Shows a "not initialized" gate screen when the SDK has not yet been enabled.
struct DiagnosticsView: View {

    @Environment(IntelSDKManager.self) private var manager

    var body: some View {
        NavigationStack {
            if self.manager.isInitialized {
                List {
                    Section {
                        NavigationLink {
                            CrashReportingView()
                        } label: {
                            Label("Crash Reporting", systemImage: "exclamationmark.triangle")
                        }

                        NavigationLink {
                            BreadcrumbsView()
                        } label: {
                            Label("Breadcrumbs", systemImage: "bookmark")
                        }

                        NavigationLink {
                            ErrorLoggingView()
                        } label: {
                            Label("Error & Exception Logging", systemImage: "xmark.octagon")
                        }
                    } header: {
                        SectionHeaderView(
                            title: "Diagnostics Features",
                            systemImage: "cross.case",
                            description: "Crash reporting, breadcrumbs, and error & exception logging."
                        )
                    }
                }
                .listStyle(.insetGrouped)
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
