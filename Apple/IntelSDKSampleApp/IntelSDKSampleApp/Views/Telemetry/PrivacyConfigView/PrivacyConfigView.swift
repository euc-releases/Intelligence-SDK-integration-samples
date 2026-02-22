//
//  PrivacyConfigView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK


// MARK: - Constants

private enum PrivacyConfigConstants {
    static let dexDocsURL = "https://docs.omnissa.com/bundle/Intelligence/page/IntelDEXSupportedDataByProdApp.html"

    static let batteryAttributes = ["plugged_type", "battery_level", "battery_type"]
    static let batteryEvents = ["charging_state_change"]

    static let deviceAttributes = ["location_latitude", "location_longitude", "model", "os_name"]
    static let deviceEvents: [String] = ["device_reboot"]

    static let networkAttributes = ["jitter", "latency"]
    static let networkEvents = ["network_change"]
}

// MARK: - PrivacyConfigView

/// Demonstrates the WS1 Intelligence SDK Privacy Configuration feature.
///
/// Provides a visual JSON builder for DEXData (BatteryData, DeviceData, NetworkData)
/// with DisableAll toggles, attribute/event pickers, pre-built templates, raw JSON
/// preview, and Apply button calling setSDKControlConfig.
struct PrivacyConfigView: View {

    // MARK: - Toast State

    @State var toastMessage: String?

    // MARK: - Privacy Config State

    @State var batteryDisableAll: Bool = false
    @State var deviceDisableAll: Bool = false
    @State var networkDisableAll: Bool = false

    @State var batteryAttributesToDisable: Set<String> = []
    @State var deviceAttributesToDisable: Set<String> = []
    @State var networkAttributesToDisable: Set<String> = []

    @State var batteryEventsToDisable: Set<String> = []
    @State var deviceEventsToDisable: Set<String> = []
    @State var networkEventsToDisable: Set<String> = []

    // MARK: - Body

    var body: some View {
        Form {
            self.templatesSection
            self.batteryDataSection
            self.deviceDataSection
            self.networkDataSection
            self.jsonPreviewSection
            self.applySection
            self.referenceLinkSection
        }
        .navigationTitle("Privacy Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: self.$toastMessage, duration: 2)
    }

    // MARK: - Section: Templates

    private var templatesSection: some View {
        Section {
            HStack(spacing: 12) {
                self.templateButton(title: "All Enabled") {
                    self.applyTemplateAllEnabled()
                }
                self.templateButton(title: "Battery Only") {
                    self.applyTemplateBatteryOnly()
                }
            }
            HStack(spacing: 12) {
                self.templateButton(title: "Network Only") {
                    self.applyTemplateNetworkOnly()
                }
                self.templateButton(title: "All Disabled") {
                    self.applyTemplateAllDisabled()
                }
            }
        } header: {
            SectionHeaderView(
                title: "Pre-Built Templates",
                systemImage: "doc.on.doc",
                description: "Apply a template to quickly configure privacy settings."
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

    // MARK: - Section: BatteryData

    private var batteryDataSection: some View {
        Section {
            Toggle(isOn: self.$batteryDisableAll) {
                HStack(spacing: 8) {
                    Image(systemName: "power")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Disable All Battery Data")
                }
            }

            if self.batteryDisableAll {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    Text("DisableAll overrides Attributes and Events for this category.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                self.attributeEventPickers(
                    attributes: PrivacyConfigConstants.batteryAttributes,
                    events: PrivacyConfigConstants.batteryEvents,
                    attributesDisabled: self.$batteryAttributesToDisable,
                    eventsDisabled: self.$batteryEventsToDisable
                )
            }
        } header: {
            SectionHeaderView(
                title: "Battery Data",
                systemImage: "battery.100",
                description: "Control battery entity attributes and events."
            )
        }
    }

    // MARK: - Section: DeviceData

    private var deviceDataSection: some View {
        Section {
            Toggle(isOn: self.$deviceDisableAll) {
                HStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Disable All Device Data")
                }
            }

            if self.deviceDisableAll {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    Text("DisableAll overrides Attributes and Events for this category.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                self.attributeEventPickers(
                    attributes: PrivacyConfigConstants.deviceAttributes,
                    events: PrivacyConfigConstants.deviceEvents,
                    attributesDisabled: self.$deviceAttributesToDisable,
                    eventsDisabled: self.$deviceEventsToDisable
                )
            }
        } header: {
            SectionHeaderView(
                title: "Device Data",
                systemImage: "cpu",
                description: "Control device entity attributes and events."
            )
        }
    }

    // MARK: - Section: NetworkData

    private var networkDataSection: some View {
        Section {
            Toggle(isOn: self.$networkDisableAll) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Disable All Network Data")
                }
            }

            if self.networkDisableAll {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    Text("DisableAll overrides Attributes and Events for this category.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                self.attributeEventPickers(
                    attributes: PrivacyConfigConstants.networkAttributes,
                    events: PrivacyConfigConstants.networkEvents,
                    attributesDisabled: self.$networkAttributesToDisable,
                    eventsDisabled: self.$networkEventsToDisable
                )
            }
        } header: {
            SectionHeaderView(
                title: "Network Data",
                systemImage: "antenna.radiowaves.left.and.right",
                description: "Control network entity attributes and events."
            )
        }
    }

    // MARK: - Attribute/Event Pickers

    @ViewBuilder
    private func attributeEventPickers(attributes: [String], events: [String],
                                       attributesDisabled: Binding<Set<String>>, eventsDisabled: Binding<Set<String>> ) -> some View {
        if !attributes.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Attributes to Disable")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(attributes, id: \.self) { attr in
                    Toggle(attr, isOn: Binding(
                        get: { attributesDisabled.wrappedValue.contains(attr) },
                        set: { on in
                            if on {
                                attributesDisabled.wrappedValue.insert(attr)
                            } else {
                                attributesDisabled.wrappedValue.remove(attr)
                            }
                        }
                    ))
                }
            }
            .padding(.vertical, 4)
        }

        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Events to Disable")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(events, id: \.self) { event in
                    Toggle(event, isOn: Binding(
                        get: { eventsDisabled.wrappedValue.contains(event) },
                        set: { on in
                            if on {
                                eventsDisabled.wrappedValue.insert(event)
                            } else {
                                eventsDisabled.wrappedValue.remove(event)
                            }
                        }
                    ))
                }
            }
            .padding(.vertical, 4)
        }
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
                title: "Raw JSON Preview",
                systemImage: "curlybraces",
                description: "The constructed DEXData configuration that will be applied."
            )
        }
    }

    // MARK: - Section: Apply

    private var applySection: some View {
        Section {
            Button {
                self.applyConfiguration()
            } label: {
                HStack {
                    Spacer()
                    Label("Apply Configuration", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Section: Reference Link

    private var referenceLinkSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("For the complete list of iOS attributes and events you can enable or disable, see the Omnissa DEX Supported Data reference (iOS section).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: PrivacyConfigConstants.dexDocsURL)!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("Omnissa DEX Supported Data")
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(
                title: "Reference",
                systemImage: "book",
                description: "Full list of DEX attributes and events by platform."
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyConfigView()
            .environment(IntelSDKManager())
    }
}
