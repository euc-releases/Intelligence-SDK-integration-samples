//
//  NetworkInsightsView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK


// MARK: - Supporting Types

/// The result of a live sample request fired from the Automatic Capture demo section.
struct SampleRequestResult: Identifiable {
    let id = UUID()
    let label: String
    let url: String
    let statusCode: Int?
    let bytesReceived: Int?
    let latencyMs: Double?
    let error: String?
    let firedAt: Date

    var isSuccess: Bool { self.error == nil }
}

/// A URL filter entry tracked locally for display.
struct FilterEntry: Identifiable {
    let id = UUID()
    let token: String
    let type: WS1FilterType
    let addedAt: Date

    var typeLabel: String {
        switch self.type {
        case .deny:               return "Deny"
        case .preserveQuery:      return "Preserve Query"
        case .preserveFragment:   return "Preserve Fragment"
        case .preserveParameters: return "Preserve Parameters"
        case .preserveAll:        return "Preserve All"
        @unknown default:         return "Unknown"
        }
    }

    var typeSystemImage: String {
        switch self.type {
        case .deny:               return "nosign"
        case .preserveQuery:      return "questionmark.circle"
        case .preserveFragment:   return "number"
        case .preserveParameters: return "slider.horizontal.3"
        case .preserveAll:        return "checkmark.shield"
        @unknown default:         return "circle"
        }
    }
}

/// A manually logged network request entry tracked locally for display.
struct ManualLogEntry: Identifiable {
    let id = UUID()
    let method: String
    let urlString: String
    let responseCode: Int
    let latencyMs: Int
    let bytesRead: UInt
    let bytesSent: UInt
    let errorDescription: String?
    let loggedAt: Date
}

// MARK: - NetworkInsightsView

/// Demonstrates the WS1 Intelligence SDK Network Insights (APM) feature.
///
/// Network Insights automatically captures performance data for all NSURLSession and
/// NSURLConnection requests when service monitoring is enabled. This view covers:
///
/// - A read-only display of the APM configuration set before SDK initialization
/// - A live demo showing automatic capture of real network requests
/// - Manual network request logging for non-standard network libraries
/// - Dynamic URL filter management to suppress specific endpoints from reporting
/// - Location update to associate geographic context with network events
struct NetworkInsightsView: View {
    @Environment(IntelSDKManager.self) private var manager

    // MARK: - Automatic Capture State

    @State var sampleResults: [SampleRequestResult] = []
    @State var isFiringSuccess: Bool = false
    @State var isFiringFailure: Bool = false

    // MARK: - Manual Logging State

    @State var manualMethod: String = "GET"
    @State var manualURL: String = "https://httpbin.org/get"
    @State var manualLatencyMs: String = "120"
    @State var manualBytesRead: String = "2048"
    @State var manualBytesSent: String = "512"
    @State var manualResponseCode: String = "200"
    @State var manualErrorDescription: String = ""
    @State var manualLog: [ManualLogEntry] = []

    // MARK: - URL Filter State

    @State var filterToken: String = ""
    @State var filterType: WS1FilterType = .deny
    @State var filters: [FilterEntry] = []

    // MARK: - Location State

    @State private var latitudeText: String = "37.7749"
    @State private var longitudeText: String = "-122.4194"

    // MARK: - Toast

    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    let httpMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]

    // MARK: - Body

    var body: some View {
        Form {
            self.apmConfigSection
            self.automaticCaptureSection
            self.manualLoggingSection
            self.urlFiltersSection
            self.locationSection
        }
        .navigationTitle("Network Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !self.sampleResults.isEmpty || !self.manualLog.isEmpty {
                    Button("Clear") {
                        self.sampleResults.removeAll()
                        self.manualLog.removeAll()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if self.showToast {
                Text(self.toastMessage)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: self.showToast)
    }

    // MARK: - Section: APM Configuration (Pre-Init, Read-Only)

    private var apmConfigSection: some View {
        Section {
            self.lockedToggleRow(
                label: "Service Monitoring",
                icon: "antenna.radiowaves.left.and.right",
                value: self.manager.enableServiceMonitoring
            )
            self.lockedToggleRow(
                label: "Monitor NSURLSession",
                icon: "network",
                value: self.manager.monitorNSURLSession
            )
            self.lockedToggleRow(
                label: "Monitor NSURLConnection",
                icon: "cable.connector",
                value: self.manager.monitorNSURLConnection
            )
            self.lockedToggleRow(
                label: "Monitor WKWebView",
                icon: "globe",
                value: self.manager.monitorWKWebView
            )

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .padding(.top, 2)
                Text("These were set before SDK initialization. Restart the app to change them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "APM Configuration",
                systemImage: "gearshape.2",
                description: "Network monitoring options configured before SDK init. Immutable for this session."
            )
        }
    }

    // MARK: - Section: Location Update

    private var locationSection: some View {
        Section {
            InfoRowView(
                icon: "location.fill",
                color: .teal,
                title: "Location & Network Events",
                infoBody: "The SDK does not request location access itself. Provide the device's current coordinates here to associate geographic context with all subsequent network events reported to the Intelligence backend."
            )

            HStack {
                Text("Latitude")
                Spacer()
                TextField("37.7749", text: self.$latitudeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }

            HStack {
                Text("Longitude")
                Spacer()
                TextField("-122.4194", text: self.$longitudeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }

            Button {
                self.updateLocation()
            } label: {
                HStack {
                    Spacer()
                    Label("Update Location", systemImage: "location.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(
                Double(self.latitudeText) == nil ||
                Double(self.longitudeText) == nil
            )

            CodeSnippetView(code: """
                // WS1Intelligence.updateLocation(toLatitude:longitude:)
                // Associates a lat/lon with all subsequent network events in this session.
                // The SDK does not obtain location access itself; the app must supply it.
                WS1Intelligence.updateLocation(toLatitude: 37.7749, longitude: -122.4194)
                """)

        } header: {
            SectionHeaderView(
                title: "Location Update",
                systemImage: "location.circle",
                description: "Tie geographic context to network events for location-aware analysis on the portal."
            )
        } footer: {
            Text("Introduced in SDK v5.9.3. Location coordinates are sent with subsequent network event payloads.")
                .font(.caption)
        }
    }

    // MARK: - SDK Actions

    /// Updates the SDK's location context for subsequent network events.
    private func updateLocation() {
        guard let lat = Double(self.latitudeText), let lon = Double(self.longitudeText) else {
            return
        }

        // WS1Intelligence.updateLocation(toLatitude:longitude:)
        // Provides the device's current geographic coordinates to the SDK. The SDK does not
        // request CoreLocation access itself — it is the app's responsibility to obtain location
        // permission and supply coordinates here. Once set, the coordinates are attached to
        // all subsequent network event payloads sent to the Intelligence backend, enabling
        // location-aware analysis and geographic filtering on the portal.
        // Introduced in SDK v5.9.3.
        WS1Intelligence.updateLocation(toLatitude: lat, longitude: lon)
        self.presentToast(String(format: "Location updated (%.4f, %.4f) ✓", lat, lon))
    }

    // MARK: - Presentation Helpers

    func presentToast(_ message: String) {
        self.toastMessage = message
        self.showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = false
        }
    }

    // MARK: - Reusable Sub-Views

    /// A toggle-style row that always appears locked (non-interactive), reflecting a pre-init frozen config value.
    @ViewBuilder
    private func lockedToggleRow(label: String, icon: String, value: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(label)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(value ? .green : .red)
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        NetworkInsightsView()
            .environment(IntelSDKManager())
    }
}
