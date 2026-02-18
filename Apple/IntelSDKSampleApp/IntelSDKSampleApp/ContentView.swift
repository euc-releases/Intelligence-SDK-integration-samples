//
//  ContentView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI


/// Each tab other than Dashboard gates its content behind an `isInitialized` check inside
/// the tab's own view, guiding the user to complete the initialization flow first.
struct ContentView: View {

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.medium")
                }

            DiagnosticsView()
                .tabItem {
                    Label("Diagnostics", systemImage: "cross.case")
                }

            PerformanceView()
                .tabItem {
                    Label("Performance", systemImage: "chart.xyaxis.line")
                }

            TelemetryView()
                .tabItem {
                    Label("Telemetry", systemImage: "antenna.radiowaves.left.and.right")
                }

            ConfigurationView()
                .tabItem {
                    Label("Configuration", systemImage: "gearshape.2")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(IntelSDKManager())
}
