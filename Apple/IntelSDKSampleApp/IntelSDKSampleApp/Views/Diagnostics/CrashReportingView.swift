//
//  CrashReportingView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

/// Demonstrates the WS1 Intelligence SDK crash reporting feature.
///
/// Crash capture is entirely automatic once the SDK is initialized — no additional code is
/// required to instrument crashes. This view surfaces the crash status from the previous
/// session, shows the details delivered via the crash notification, explains the offline
/// caching behaviour, and provides a controlled way to trigger a test crash.
struct CrashReportingView: View {

    @Environment(IntelSDKManager.self) private var manager
    @State private var showCrashConfirmation = false

    var body: some View {
        Form {
            self.crashStatusSection
            self.offlineCachingSection
            self.simulateCrashSection
        }
        .navigationTitle("Crash Reporting")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Simulate Crash?", isPresented: self.$showCrashConfirmation) {
            Button("Crash Now", role: .destructive) {
                // fatalError(_:)
                // Immediately terminates the process with the given message, simulating an
                // unhandled crash. The WS1 Intelligence SDK's crash handler intercepts the
                // resulting signal and writes a crash report to disk before the process exits.
                // On the next launch, the SDK reads the saved report, sets didCrashOnLastLoad()
                // to true, and posts WS1NotificationDidCrashOnLastLoad with the crash details.
                //
                // Constraint: the Xcode debugger must be detached before triggering this crash.
                // When a debugger is attached it intercepts the signal first, preventing the SDK
                // crash handler from running. Use Xcode ▸ Debug ▸ Detach, or stop the app from
                // Xcode and relaunch it manually from the device or simulator.
                fatalError("Test crash triggered from IntelSDK Sample App")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will immediately terminate the app. The crash will be captured by the SDK and reported on the next launch.\n\nMake sure to disconnect the Xcode debugger first — otherwise the crash handler cannot run.")
        }
    }

    // MARK: - Crash Status Section

    private var crashStatusSection: some View {
        Section {
            // WS1Intelligence.didCrashOnLastLoad()
            // Returns true if the SDK recorded an unhandled crash during the previous app
            // session. The value is determined at enable() time by checking for a crash
            // report written to disk during the prior run. It does not change during the
            // current session.
            //
            // Use this to surface a crash indicator in the UI or to trigger first-launch
            // crash recovery logic (e.g. clearing corrupted local state).
            LabeledContent("Last Session") {
                if self.manager.crashedOnLastLoad {
                    Text("Crashed")
                        .foregroundStyle(.red)
                        .fontWeight(.medium)
                } else {
                    Text("Clean Exit")
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
            }

            // WS1NotificationDidCrashOnLastLoad / WS1NotificationCrashNameKey,
            //   WS1NotificationCrashReasonKey, WS1NotificationCrashDateKey
            // The SDK posts WS1NotificationDidCrashOnLastLoad on the main queue during enable()
            // when a prior crash is detected. The notification's userInfo contains the crash
            // signal name, a human-readable reason, and the timestamp of the crash.
            //
            // These values are captured by IntelSDKManager's init()-time observer and stored
            // in lastCrashName, lastCrashReason, and lastCrashDate. Showing them here gives
            // developers immediate visibility into what type of crash occurred.
            if self.manager.crashedOnLastLoad {
                if let name = self.manager.lastCrashName {
                    LabeledContent("Crash Name", value: name)
                        .font(.subheadline)
                }
                if let reason = self.manager.lastCrashReason {
                    LabeledContent("Reason") {
                        Text(reason)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                if let date = self.manager.lastCrashDate {
                    LabeledContent("Crash Date", value: date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            SectionHeaderView(
                title: "Crash Status",
                systemImage: "exclamationmark.triangle",
                description: "Whether the app crashed on its previous run. Populated at SDK initialization."
            )
        } footer: {
            Text("Crash capture is automatic once the SDK is initialized. No additional instrumentation is required.")
                .font(.caption)
        }
    }

    // MARK: - Offline Caching Section

    private var offlineCachingSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Offline Crash Caching")
                        .font(.headline)
                    Text("If the device is offline when a crash occurs, the SDK caches the crash report locally and uploads it the next time connectivity is available. By default, up to **3 crashes** are cached on device. If more crashes occur while offline, the oldest cached report is overwritten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.blue.opacity(0.07))
    }

    // MARK: - Simulate Crash Section

    private var simulateCrashSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disconnect Debugger First")
                        .font(.headline)
                    Text("When the Xcode debugger is attached, it intercepts crash signals before the SDK crash handler can run. To test crash reporting, detach first:\n\n• In Xcode: **Debug ▸ Detach**\n• Or stop the app from Xcode, then relaunch it manually from the device or simulator.\n\nAfter the crash, relaunch the app and return here to see the crash details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button(role: .destructive) {
                self.showCrashConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Simulate Crash", systemImage: "bolt.trianglebadge.exclamationmark")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        } header: {
            SectionHeaderView(
                title: "Simulate Crash",
                systemImage: "bolt.trianglebadge.exclamationmark",
                description: "Trigger a deliberate crash to verify the SDK captures and reports it correctly."
            )
        } footer: {
            Text("The simulated crash calls fatalError(), which the SDK's signal handler intercepts. The crash report is sent to the Intelligence portal on the next app launch.")
                .font(.caption)
        }
        .listRowBackground(Color.orange.opacity(0.06))
    }
}

#Preview {
    NavigationStack {
        CrashReportingView()
            .environment(IntelSDKManager())
    }
}
