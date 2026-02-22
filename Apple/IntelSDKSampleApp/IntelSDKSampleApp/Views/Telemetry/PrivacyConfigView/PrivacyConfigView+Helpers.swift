//
//  PrivacyConfigView+Helpers.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI
import WS1IntelligenceSDK


extension PrivacyConfigView {

    // MARK: - JSON Generation

    var builtConfigJSON: String {
        let batteryData: [String: Any] = self.buildCategoryConfig(
            disableAll: self.batteryDisableAll,
            attributes: self.batteryAttributesToDisable,
            events: self.batteryEventsToDisable
        )
        let deviceData: [String: Any] = self.buildCategoryConfig(
            disableAll: self.deviceDisableAll,
            attributes: self.deviceAttributesToDisable,
            events: self.deviceEventsToDisable
        )
        let networkData: [String: Any] = self.buildCategoryConfig(
            disableAll: self.networkDisableAll,
            attributes: self.networkAttributesToDisable,
            events: self.networkEventsToDisable
        )

        let dexData: [String: Any] = [
            "Version": 1.0,
            "BatteryData": batteryData,
            "DeviceData": deviceData,
            "NetworkData": networkData
        ]

        let root: [String: Any] = ["DEXData": dexData]

        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys, .prettyPrinted]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func buildCategoryConfig(disableAll: Bool, attributes: Set<String>, events: Set<String>) -> [String: Any] {
        var dict: [String: Any] = ["DisableAll": disableAll]
        if !disableAll {
            dict["AttributesToDisable"] = Array(attributes).sorted()
            dict["EventsToDisable"] = Array(events).sorted()
        }
        return dict
    }

    // MARK: - Template Actions

    func applyTemplateAllEnabled() {
        self.batteryDisableAll = false
        self.deviceDisableAll = false
        self.networkDisableAll = false
        self.clearDisableSet()
    }

    func applyTemplateBatteryOnly() {
        self.batteryDisableAll = false
        self.deviceDisableAll = true
        self.networkDisableAll = true
        self.clearDisableSet()
    }

    func applyTemplateNetworkOnly() {
        self.batteryDisableAll = true
        self.deviceDisableAll = true
        self.networkDisableAll = false
        self.clearDisableSet()
    }

    func applyTemplateAllDisabled() {
        self.batteryDisableAll = true
        self.deviceDisableAll = true
        self.networkDisableAll = true
        self.clearDisableSet()
    }

    private func clearDisableSet() {
        self.batteryAttributesToDisable = []
        self.deviceAttributesToDisable = []
        self.networkAttributesToDisable = []
        self.batteryEventsToDisable = []
        self.deviceEventsToDisable = []
        self.networkEventsToDisable = []
    }

    // MARK: - Apply Configuration

    func applyConfiguration() {
        let json = self.builtConfigJSON

        // WS1Intelligence.setSDKControlConfig(_:)
        // Injects the control configuration (Custom UEM SDK Settings) JSON string.
        // Parses DEXData (privacy config) and IntelSDKAllowedApps from the payload.
        // Call ideally before enabling Telemetry Features; mutable anytime post-init.
        // SDK saves the config; nil or empty string leaves previous config unchanged.
        WS1Intelligence.setSDKControlConfig(json)

        self.toastMessage = "Privacy configuration applied ✓"
    }
}
