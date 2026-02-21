//
//  ErrorLoggingView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - Supporting Types

/// Pre-defined error domains available in the NSError section.
/// The `.custom` case unlocks a free-form text field so the user can type any domain string.
private enum ErrorDomain: String, CaseIterable, Identifiable {
    case app      = "com.example.app"
    case network  = "com.example.network"
    case database = "com.example.database"
    case custom   = "Custom"

    var id: String { self.rawValue }
}

/// A single entry in the session history list.
/// Tracks what kind of item was logged, a short human-readable summary, and when it occurred.
/// Never persisted — resets on every app launch.
private struct LoggedItem: Identifiable {
    let id = UUID()
    let kind: Kind
    let summary: String
    let timestamp: Date

    enum Kind: String {
        case nsError            = "NSError"
        case nsErrorStacktrace  = "NSError + Stacktrace"
        case nsException        = "NSException"

        var systemImage: String {
            switch self {
            case .nsError:           return "exclamationmark.circle"
            case .nsErrorStacktrace: return "list.number"
            case .nsException:       return "bolt.trianglebadge.exclamationmark"
            }
        }

        var color: Color {
            switch self {
            case .nsError:           return .orange
            case .nsErrorStacktrace: return .purple
            case .nsException:       return .red
            }
        }
    }
}

// MARK: - ErrorLoggingView

/// Demonstrates the WS1 Intelligence SDK error and exception logging APIs.
///
/// The SDK exposes three closely related calls, each surfacing reported items in the
/// "Handled Exceptions" area of the Omnissa Intelligence portal:
///
/// - `logError(_:)` — logs an NSError with a live thread stacktrace.
/// - `logError(_:stacktrace:)` — logs an NSError with a caller-supplied array of stack frame
///   strings, useful for cross-platform (Flutter, React Native) or pre-symbolicated reports.
/// - `logHandledException(_:)` — logs a handled NSException caught in a try/catch block,
///   thrown by a third-party library, or used to represent non-fatal error conditions.
///
/// This view exposes all three calls with configurable inputs and records a local
/// session history to confirm that each call was made.
struct ErrorLoggingView: View {

    @Environment(IntelSDKManager.self) private var manager

    // MARK: NSError state
    @State private var selectedDomain: ErrorDomain = .app
    @State private var customDomain: String = ""
    @State private var errorCode: String = "42"
    @State private var errorDescription: String = "Something went wrong in the sample app."

    // MARK: Stacktrace state (Section 2 reuses domain/code/description above)
    @State private var stacktraceText: String = """
        0  MyApp                  MyViewController.loadData() + 128
        1  MyApp                  MyViewController.viewDidLoad() + 64
        2  UIKitCore               UIViewController.loadViewIfRequired() + 172
        3  UIKitCore               UIViewController.view.getter + 28
        """

    // MARK: NSException state
    @State private var exceptionName: String = "NSGenericException"
    @State private var exceptionReason: String = "A handled exception occurred in the sample app."

    // MARK: UI state
    @State private var history: [LoggedItem] = []
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    var body: some View {
        Form {
            self.nsErrorSection
            self.nsErrorStacktraceSection
            self.nsExceptionSection
            self.historySection
        }
        .navigationTitle("Error & Exception Logging")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !self.history.isEmpty {
                    Button("Clear History") {
                        self.history.removeAll()
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

    // MARK: - Section 1: Log NSError

    private var nsErrorSection: some View {
        Section {
            Picker("Domain", selection: self.$selectedDomain) {
                ForEach(ErrorDomain.allCases) { domain in
                    Text(domain == .custom ? "Custom…" : domain.rawValue)
                        .tag(domain)
                }
            }

            if self.selectedDomain == .custom {
                TextField("com.yourapp.module", text: self.$customDomain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            HStack {
                Text("Code")
                Spacer()
                TextField("42", text: self.$errorCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            TextField("Description", text: self.$errorDescription)

            Button {
                self.logNSError()
            } label: {
                HStack {
                    Spacer()
                    Label("Log NSError", systemImage: "exclamationmark.circle.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!self.isNSErrorInputValid)

            CodeSnippetView(code: """
                let error = NSError(
                    domain: "com.example.app",
                    code: 42,
                    userInfo: [NSLocalizedDescriptionKey: "Something went wrong."]
                )
                WS1Intelligence.logError(error)
                """, label: "SDK call")

        } header: {
            SectionHeaderView(
                title: "Log NSError",
                systemImage: "exclamationmark.circle",
                description: "Reports an NSError to the portal. The SDK captures the calling thread's stack trace and groups errors by stacktrace — similar to how crash reports are grouped."
            )
        } footer: {
            Text("Logged errors appear in the \"Handled Exceptions\" area of the Omnissa Intelligence portal. Use this for NSErrors from Apple APIs, networking, and third-party libraries.")
                .font(.caption)
        }
    }

    // MARK: - Section 2: Log NSError with Custom Stacktrace

    private var nsErrorStacktraceSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("When to use a custom stacktrace")
                        .font(.headline)
                    Text("Pass a caller-supplied array of stack frame strings instead of capturing a live thread stacktrace. Introduced in SDK v5.9.1.\n\nIdeal for cross-platform apps (Flutter, React Native, Cordova) where the crash originated in a non-native layer, or when you have a pre-symbolicated report from another tool.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Stack frames (one per line)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Stack frames…", text: self.$stacktraceText, axis: .vertical)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(5, reservesSpace: true)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Button {
                self.logNSErrorWithStacktrace()
            } label: {
                HStack {
                    Spacer()
                    Label("Log with Stacktrace", systemImage: "list.number")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!self.isNSErrorInputValid || self.stacktraceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            CodeSnippetView(code: """
                let frames = [
                    "0  MyApp  MyViewController.loadData() + 128",
                    "1  MyApp  MyViewController.viewDidLoad() + 64",
                    "2  UIKitCore  UIViewController.loadViewIfRequired() + 172"
                ]
                WS1Intelligence.logError(error, stacktrace: frames)
                """, label: "SDK call")

        } header: {
            SectionHeaderView(
                title: "Log NSError with Custom Stacktrace",
                systemImage: "list.number",
                description: "Same as Log NSError but uses the domain, code, and description from Section 1 paired with a custom array of stack frame strings you supply."
            )
        } footer: {
            Text("This overload reuses the NSError inputs above. Edit the domain, code, and description in Section 1 before tapping \"Log with Stacktrace\".")
                .font(.caption)
        }
        .listRowBackground(Color.purple.opacity(0.07))
    }

    // MARK: - Section 3: Log Handled Exception

    private var nsExceptionSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Handled Exceptions vs. Crashes")
                        .font(.headline)
                    Text("A handled exception is an NSException your code catches and recovers from — the app continues running. Use this API for exceptions caught in try/catch blocks, raised by third-party libraries, or used to represent error conditions like low-memory warnings. The SDK does NOT re-raise or rethrow the exception.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            TextField("Exception name", text: self.$exceptionName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            TextField("Reason", text: self.$exceptionReason)

            Button {
                self.logHandledException()
            } label: {
                HStack {
                    Spacer()
                    Label("Log Handled Exception", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(self.exceptionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            CodeSnippetView(code: """
                let exception = NSException(
                    name: NSExceptionName("NSGenericException"),
                    reason: "A handled exception occurred.",
                    userInfo: nil
                )
                WS1Intelligence.logHandledException(exception)
                """, label: "SDK call")

        } header: {
            SectionHeaderView(
                title: "Log Handled Exception",
                systemImage: "bolt.trianglebadge.exclamationmark",
                description: "Reports a handled NSException to the portal. Exceptions are grouped by stacktrace and appear in \"Handled Exceptions\" — the app keeps running after the call."
            )
        } footer: {
            Text("Common use cases: exceptions thrown by third-party libraries, assertions converted to exceptions, or non-fatal error conditions treated as exceptions.")
                .font(.caption)
        }
        .listRowBackground(Color.red.opacity(0.07))
    }

    // MARK: - Section 4: Session History

    private var historySection: some View {
        Section {
            if self.history.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "xmark.octagon")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No errors or exceptions logged yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(self.history.reversed()) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.kind.systemImage)
                            .foregroundStyle(item.kind.color)
                            .font(.subheadline)
                            .frame(width: 20)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(item.kind.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(item.kind.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.kind.color.opacity(0.12), in: Capsule())
                            }
                            Text(item.summary)
                                .font(.subheadline)
                            Text(item.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            SectionHeaderView(
                title: "Session History",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                description: "All errors and exceptions logged during this session. Local only — not persisted and resets on relaunch."
            )
        } footer: {
            if !self.history.isEmpty {
                Text("\(self.history.count) item\(self.history.count == 1 ? "" : "s") logged this session.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Helpers

    /// Resolved domain string — either the selected preset or the typed custom value.
    private var resolvedDomain: String {
        self.selectedDomain == .custom ? self.customDomain : self.selectedDomain.rawValue
    }

    /// Resolved integer error code from the text field, defaulting to 0 on invalid input.
    private var resolvedCode: Int {
        Int(self.errorCode) ?? 0
    }

    /// True when the minimum NSError inputs are non-empty and valid.
    private var isNSErrorInputValid: Bool {
        let domain = self.resolvedDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        return !domain.isEmpty && !self.errorDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Calls `WS1Intelligence.logError(_:)` with the current NSError inputs.
    private func logNSError() {
        let domain = self.resolvedDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = self.errorDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // WS1Intelligence.logError(_:)
        // Reports an NSError to the Intelligence portal. The SDK captures the current
        // thread's stack trace and groups errors by stacktrace — similar to crash reports.
        // Logged errors appear in the "Handled Exceptions" area of the portal.
        // Use this for any NSError your app receives that represents a meaningful failure,
        // including errors from Apple APIs and third-party libraries.
        let error = NSError(
            domain: domain,
            code: self.resolvedCode,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
        WS1Intelligence.logError(error)

        let summary = "[\(domain) \(self.resolvedCode)] \(description)"
        self.history.append(LoggedItem(kind: .nsError, summary: summary, timestamp: Date()))
        self.presentToast("NSError logged")
    }

    /// Calls `WS1Intelligence.logError(_:stacktrace:)` with the current inputs and custom frames.
    private func logNSErrorWithStacktrace() {
        let domain = self.resolvedDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = self.errorDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let frames = self.stacktraceText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // WS1Intelligence.logError(_:stacktrace:)
        // Same as logError(_:) but accepts a caller-supplied array of stack frame strings
        // instead of capturing the live thread stacktrace. Introduced in SDK v5.9.1.
        // Use this when you have a symbolicated or cross-platform stacktrace (e.g. from a
        // JavaScript crash, a Flutter error, or a pre-symbolicated report) that you want
        // to associate with this NSError on the Intelligence portal.
        // Each element in the array represents one frame; the SDK forwards the array as-is
        // without further symbolication.
        let error = NSError(
            domain: domain,
            code: self.resolvedCode,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
        WS1Intelligence.logError(error, stacktrace: frames)

        let summary = "[\(domain) \(self.resolvedCode)] \(description) (\(frames.count) frames)"
        self.history.append(LoggedItem(kind: .nsErrorStacktrace, summary: summary, timestamp: Date()))
        self.presentToast("NSError with stacktrace logged")
    }

    /// Calls `WS1Intelligence.logHandledException(_:)` with the current exception inputs.
    private func logHandledException() {
        let name = self.exceptionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = self.exceptionReason.trimmingCharacters(in: .whitespacesAndNewlines)

        // WS1Intelligence.logHandledException(_:)
        // Reports a handled NSException to the Intelligence portal. Exceptions are grouped
        // by stacktrace and appear in the "Handled Exceptions" area — the same place as
        // logError results. Use this for exceptions caught in try/catch blocks, thrown by
        // third-party libraries, or used to represent error-like conditions (e.g. low-memory
        // warnings, assertion-style checks). The SDK does NOT re-raise or rethrow the
        // exception; the app continues running normally after the call.
        let exception = NSException(
            name: NSExceptionName(name),
            reason: reason.isEmpty ? nil : reason,
            userInfo: nil
        )
        WS1Intelligence.logHandledException(exception)

        let summary = "\(name): \(reason.isEmpty ? "(no reason)" : reason)"
        self.history.append(LoggedItem(kind: .nsException, summary: summary, timestamp: Date()))
        self.presentToast("Handled exception logged")
    }

    /// Displays a bottom toast message for 1.5 seconds.
    private func presentToast(_ message: String) {
        self.toastMessage = message
        self.showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showToast = false
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        ErrorLoggingView()
            .environment(IntelSDKManager())
    }
}
