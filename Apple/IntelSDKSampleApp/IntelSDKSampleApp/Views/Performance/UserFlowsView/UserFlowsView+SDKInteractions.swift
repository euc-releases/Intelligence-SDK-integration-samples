//
//  UserFlowsView+SDKInteractions.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import Foundation
import WS1IntelligenceSDK


extension UserFlowsView {

    // MARK: - SDK Interaction Helpers

    /// Begins a user flow with the given name, and an optional timeout parsed from `timeoutText`.
    /// Records the new entry in local state.
    func beginFlow(name: String, timeoutText: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let timeout = Double(timeoutText.trimmingCharacters(in: .whitespacesAndNewlines))

        if let timeout = timeout {
            // WS1Intelligence.beginUserFlow(_:timeout:)
            // Initializes and begins a named user flow with a timeout. If the flow is not
            // ended, failed, or cancelled before `timeout` seconds elapses, the SDK
            // automatically marks it as timed out and reports it to the portal.
            // Use this API when you want to enforce a maximum acceptable duration for a
            // key interaction (e.g., a login that should complete within 30 seconds).
            // Constraint: only one active flow per name at a time — starting a second flow
            // with the same name cancels the first silently.
            WS1Intelligence.beginUserFlow(trimmed, timeout: timeout)
        } else {
            // WS1Intelligence.beginUserFlow(_:)
            // Initializes and begins a named user flow with no timeout.
            // The flow remains active until explicitly ended, failed, or cancelled by the app,
            // or until the app crashes (in which case the flow is marked as crashed).
            // All user flows — except cancelled ones — appear on the Omnissa Intelligence
            // portal under the User Flows section.
            // The SDK automatically tracks app load time as a separate user flow named
            // "Application Load" without any app-side code.
            // Constraint: only one active flow per name at a time — starting a second flow
            // with the same name cancels the first silently.
            WS1Intelligence.beginUserFlow(trimmed)
        }

        let entry = UserFlowEntry(
            name: trimmed,
            status: .running,
            startedAt: Date(),
            timeout: timeout
        )
        self.flows.append(entry)
        self.breadcrumbInputs[entry.id] = ""
        self.presentToast("Flow \"\(trimmed)\" started")
    }

    /// Ends a user flow successfully and updates the local entry.
    func endFlow(_ flow: UserFlowEntry) {
        // WS1Intelligence.endUserFlow(_:)
        // Marks an already-begun user flow as successfully completed. The SDK records the
        // flow's total duration and reports it to the portal. Use this when the key
        // interaction the flow represents has concluded successfully (e.g., the user
        // successfully logged in, a transaction completed without error).
        // Calling endUserFlow on a name that is not currently active is a no-op.
        WS1Intelligence.endUserFlow(flow.name)
        self.completeFlow(id: flow.id, status: .ended)
        self.presentToast("Flow \"\(flow.name)\" ended")
    }

    /// Marks a user flow as failed and updates the local entry.
    func failFlow(_ flow: UserFlowEntry) {
        // WS1Intelligence.failUserFlow(_:)
        // Marks an already-begun user flow as failed. The SDK records the flow's duration
        // and reports it to the portal with a "Failed" outcome. Use this when the
        // interaction the flow represents encountered an error — for example, a login
        // attempt that returned an authentication error, or a purchase that was declined.
        // Failed flows are reported just like ended flows; the "Failed" status is visible
        // in the portal alongside duration and frequency data.
        // Calling failUserFlow on a name that is not currently active is a no-op.
        WS1Intelligence.failUserFlow(flow.name)
        self.completeFlow(id: flow.id, status: .failed)
        self.presentToast("Flow \"\(flow.name)\" marked as failed")
    }

    /// Cancels a user flow (it will not appear on the portal) and removes the local entry from active state.
    func cancelFlow(_ flow: UserFlowEntry) {
        // WS1Intelligence.cancelUserFlow(_:)
        // Cancels a user flow as if it never existed. The SDK discards all tracking data
        // for this flow and does NOT send a report to the Omnissa Intelligence portal.
        // Use this when the user abandons a flow mid-way in a way that is expected and
        // not meaningful to report (e.g., the user navigated away from a checkout screen
        // without intending to complete the purchase).
        // Calling cancelUserFlow on a name that is not currently active is a no-op.
        WS1Intelligence.cancelUserFlow(flow.name)
        self.completeFlow(id: flow.id, status: .cancelled)
        self.presentToast("Flow \"\(flow.name)\" cancelled")
    }

    /// Transitions the flow with the given id to a terminal status and records completion time.
    private func completeFlow(id: UUID, status: UserFlowStatus) {
        guard let idx = self.flows.firstIndex(where: { $0.id == id }) else { return }
        self.flows[idx].status = status
        self.flows[idx].completedAt = Date()
        self.breadcrumbInputs.removeValue(forKey: id)
    }
}

