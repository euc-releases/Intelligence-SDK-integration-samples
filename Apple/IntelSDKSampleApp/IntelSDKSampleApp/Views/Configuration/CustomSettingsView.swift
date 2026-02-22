//
//  CustomSettingsView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - Constants

private enum CustomSettingsConstants {
    static let placeholderJSON = "{\"PolicyAllowCrashReporting\": true, \"CaptureDEXData\": true}"
    static let templatePolicyAllowCrashReporting = "{\"PolicyAllowCrashReporting\": true}"
    static let templateCaptureDEXData = "{\"PolicyAllowCrashReporting\": true, \"CaptureDEXData\": true}"
    static let templateIntelSDKAllowedApps = "{\"IntelSDKAllowedApps\": [\"YOUR_APP_ID_1\", \"YOUR_APP_ID_2\"]}"
}

// MARK: - CustomSettingsView

/// JSON editor for custom settings payload with pre-built templates and Allowed Apps management.
/// All post-init mutable via setSDKControlConfig. Includes overwrite warning and app-responsibility callouts.
struct CustomSettingsView: View {

    @Environment(IntelSDKManager.self) private var manager

    // MARK: - State

    @State private var customSettingsJSON: String = CustomSettingsConstants.placeholderJSON
    @State private var allowedAppIDs: [String] = []
    @State private var newAppIDInput: String = ""
    @State private var toastMessage: String?
    @State private var showInvalidJSONAlert: Bool = false

    // MARK: - Body

    var body: some View {
        Form {
            self.overwriteWarningSection
            self.appResponsibilitySection
            self.templatesSection
            self.kvpDocumentationSection
            self.jsonEditorSection
            self.allowedAppsSection
            self.jsonPreviewSection
            self.applySection
        }
        .navigationTitle("Custom Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: self.$toastMessage, duration: 2)
        .alert("Invalid JSON", isPresented: self.$showInvalidJSONAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The custom settings JSON is invalid. Please fix the syntax and try again.")
        }
    }

    // MARK: - Section: Overwrite Warning

    private var overwriteWarningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calling setSDKControlConfig here will replace any configuration you applied earlier (e.g., from Privacy Configuration). The SDK does not merge configs — each call overwrites the previous one.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Privacy config (DEXData) and Allowed Apps (IntelSDKAllowedApps) can be combined in a single JSON object and sent together in one setSDKControlConfig call.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.orange.opacity(0.08))
        }
    }

    // MARK: - Section: App Responsibility (PolicyAllowCrashReporting, CaptureDEXData)

    private var appResponsibilitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("IntelSDK does NOT directly handle PolicyAllowCrashReporting or CaptureDEXData. It is up to your app to parse these settings from the UEM payload and enable/disable Application and DEX metrics accordingly (e.g., via setOptInStatus).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.orange.opacity(0.08))
        }
    }

    // MARK: - Section: Pre-Built Templates

    private var templatesSection: some View {
        Section {
            HStack(spacing: 12) {
                self.templateButton(title: "PolicyAllowCrashReporting") {
                    self.customSettingsJSON = CustomSettingsConstants.templatePolicyAllowCrashReporting
                }
                self.templateButton(title: "CaptureDEXData") {
                    self.customSettingsJSON = CustomSettingsConstants.templateCaptureDEXData
                }
            }
            self.templateButton(title: "IntelSDKAllowedApps") {
                self.customSettingsJSON = CustomSettingsConstants.templateIntelSDKAllowedApps
            }
        } header: {
            SectionHeaderView(
                title: "Pre-Built Templates",
                systemImage: "doc.on.doc",
                description: "Apply a template to populate the JSON editor."
            )
        }
    }

    private func templateButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Section: KVP Documentation

    private var kvpDocumentationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                self.kvpDocRow(
                    key: "PolicyAllowCrashReporting",
                    description: "Boolean. Enables/disables Intelligence SDK. App must parse and act on this."
                )
                self.kvpDocRow(
                    key: "CaptureDEXData",
                    description: "Boolean. Enables/disables DEX. Void if PolicyAllowCrashReporting is false. App must parse and act on this."
                )
                self.kvpDocRow(
                    key: "IntelSDKAllowedApps",
                    description: "JSON array of App IDs allowed to transmit DEX data. Missing or empty = all apps allowed. Parsed by SDK when CaptureDEXData is true."
                )
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "Key-Value Pairs",
                systemImage: "key",
                description: "Common SDK configuration keys from UEM Custom Settings."
            )
        }
    }

    private func kvpDocRow(key: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section: Custom JSON Editor

    private var jsonEditorSection: some View {
        Section {
            TextEditor(text: self.$customSettingsJSON)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 100)
                .autocorrectionDisabled()
        } header: {
            SectionHeaderView(
                title: "Custom JSON",
                systemImage: "curlybraces",
                description: "Edit the control config JSON. Combine multiple keys as needed."
            )
        }
    }

    // MARK: - Section: Allowed Apps

    private var allowedAppsSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("App ID", text: self.$newAppIDInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    self.addAllowedAppID()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.newAppIDInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ForEach(self.allowedAppIDs, id: \.self) { appID in
                HStack {
                    Text(appID)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Button(role: .destructive) {
                        self.allowedAppIDs.removeAll { $0 == appID }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                    .padding(.top, 2)
                Text("If the array is empty or missing, all apps transmit DEX data. Only matching App IDs are allowed when the list is non-empty.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "Allowed Apps",
                systemImage: "app.badge",
                description: "Manage IntelSDKAllowedApps. Merged into the JSON when applying."
            )
        }
    }

    private func addAllowedAppID() {
        let trimmed = self.newAppIDInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !self.allowedAppIDs.contains(trimmed) else { 
            return 
        }
        self.allowedAppIDs.append(trimmed)
        self.newAppIDInput = ""
    }

    // MARK: - Section: JSON Preview

    private var jsonPreviewSection: some View {
        Section {
            ScrollView {
                Text(self.builtConfigJSON)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        } header: {
            SectionHeaderView(
                title: "Final JSON Preview",
                systemImage: "eye",
                description: "The merged config that will be applied to setSDKControlConfig."
            )
        }
    }

    private var builtConfigJSON: String {
        var root: [String: Any] = [:]
        if let data = self.customSettingsJSON.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = parsed
        }
        if !self.allowedAppIDs.isEmpty {
            root["IntelSDKAllowedApps"] = self.allowedAppIDs
        }
        guard let outputData = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys, .prettyPrinted]),
              let json = String(data: outputData, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    // MARK: - Section: Apply

    private var applySection: some View {
        Section {
            Button {
                self.applySettings()
            } label: {
                HStack {
                    Spacer()
                    Label("Apply Settings", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func applySettings() {
        // Validate: if user entered custom JSON, it must be parseable
        let trimmed = self.customSettingsJSON.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            guard let data = trimmed.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil else {
                self.showInvalidJSONAlert = true
                return
            }
        }

        let json = self.builtConfigJSON

        // WS1Intelligence.setSDKControlConfig(_:)
        // Injects the control configuration (Custom UEM SDK Settings) JSON string.
        // Parses DEXData (privacy config), IntelSDKAllowedApps, and other keys from the payload.
        // Mutable anytime post-init. SDK saves the config; nil or empty leaves previous unchanged.
        // Each call overwrites the previous config — does not merge.
        WS1Intelligence.setSDKControlConfig(json)

        self.toastMessage = "Custom settings applied ✓"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CustomSettingsView()
            .environment(IntelSDKManager())
    }
}
