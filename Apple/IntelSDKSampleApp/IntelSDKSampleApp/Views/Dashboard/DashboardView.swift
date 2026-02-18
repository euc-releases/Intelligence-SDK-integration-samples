//
//  DashboardView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

/// The entry point of the sample app's two-phase initialization flow.
///
/// **Pre-init phase:** A Form presenting every WS1Config property the user can set before
/// calling `enableSDK()`. All fields are fully editable. A prominent "Enable SDK" button
/// triggers initialization.
///
/// **Post-init phase:** A read-only summary of the frozen configuration, the SDK running
/// status, device UUID, crash-on-last-load indicator, and a live logging-level picker
/// (the only SDK setting that remains mutable post-init).
struct DashboardView: View {

    @Environment(IntelSDKManager.self) var manager

    // App ID is persisted across restarts via @AppStorage so the user doesn't have to
    // re-enter it each time during development. It is never hardcoded in source.
    @AppStorage("savedAppID") var savedAppID: String = ""

    // MARK: Local UI State

    @State var locationHelper = LocationPermissionHelper()
    @State var showEmptyAppIDAlert = false
    @State var enableErrorMessage: String? = nil
    @State var showSuccessBanner = false


    var body: some View {
        NavigationStack {
            Group {
                if self.manager.isInitialized {
                    self.postInitView
                } else {
                    self.preInitView
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if self.showSuccessBanner {
                    self.successBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: self.showSuccessBanner)
            .animation(.easeInOut(duration: 0.4), value: self.manager.isInitialized)
            .onAppear {
                // Sync the persisted App ID into the manager on first appear.
                if self.manager.appID.isEmpty {
                    self.manager.appID = self.savedAppID
                }
            }
        }
    }

    // MARK: - Pre-Init Form

    private var preInitView: some View {
        Form {
            self.appIDSection
            self.networkMonitoringSection
            self.dataCrashConfigSection
            self.dexEntitlementsSection
            self.uemDelegateSection
            self.enableSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Post-Init View

    private var postInitView: some View {
        Form {
            self.optInCalloutSection
            self.frozenConfigBannerSection
            self.sdkStatusSection
            self.frozenConfigSummarySection
            self.loggingLevelSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("WS1 Intelligence SDK enabled successfully.")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("Pre-Init") {
    DashboardView()
        .environment(IntelSDKManager())
}

#Preview("Post-Init") {
    let manager = IntelSDKManager()
    manager.isInitialized = true
    manager.userUUID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
    manager.crashedOnLastLoad = false
    manager.appID = "demo-app-id-preview"
    manager.enableServiceMonitoring = true
    manager.monitorNSURLSession = true
    manager.monitorNSURLConnection = true
    manager.monitorWKWebView = false
    manager.allowsCellularAccess = true
    manager.enableMachExceptionHandling = true
    return DashboardView()
        .environment(manager)
}

#Preview("Post-Init Crashed") {
    let manager = IntelSDKManager()
    manager.isInitialized = true
    manager.userUUID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
    manager.crashedOnLastLoad = true
    manager.appID = "demo-app-id-preview"
    return DashboardView()
        .environment(manager)
}
