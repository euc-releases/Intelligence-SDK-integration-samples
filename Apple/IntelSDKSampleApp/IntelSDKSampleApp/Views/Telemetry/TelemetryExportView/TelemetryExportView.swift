//
//  TelemetryExportView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

// MARK: - TelemetryExportView

/// Demonstrates the WS1 Intelligence SDK Telemetry Export feature.
///
/// Provides pickers for telemetry type (DEX, ZeroTrust, All), format (JSON),
/// and category (AttributeData, EventData, AllData), an Export button,
/// formatted JSON results display, and copy-to-clipboard.
struct TelemetryExportView: View {

    // MARK: - Export Option State

    @State private var selectedTelemetryType: ExportTelemetryType = .DEX
    @State private var selectedFormat: WS1TelemetryExportDataFormatType = .JSON
    @State private var selectedCategory: WS1TelemetryExportDataCategoryType = .allData

    // MARK: - Results State

    @State private var exportedJSON: String?
    @State private var isExporting: Bool = false
    @State private var toastMessage: String?

    // MARK: - Body

    var body: some View {
        Form {
            self.exportOptionsSection
            self.infoCalloutSection
            self.exportButtonSection
            self.resultsSection
        }
        .navigationTitle("Telemetry Export")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: self.$toastMessage, duration: 2)
    }

    // MARK: - Section: Export Options

    private var exportOptionsSection: some View {
        Section {
            Picker(selection: self.$selectedTelemetryType) {
                ForEach(ExportTelemetryType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Telemetry Type")
                }
            }

            Picker(selection: self.$selectedFormat) {
                Text("JSON").tag(WS1TelemetryExportDataFormatType.JSON)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Format")
                }
            }

            Picker(selection: self.$selectedCategory) {
                Text("Attribute Data").tag(WS1TelemetryExportDataCategoryType.attributeData)
                Text("Event Data").tag(WS1TelemetryExportDataCategoryType.eventData)
                Text("All Data").tag(WS1TelemetryExportDataCategoryType.allData)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Category")
                }
            }
        } header: {
            SectionHeaderView(
                title: "Export Options",
                systemImage: "slider.horizontal.3",
                description: "Choose telemetry type, format, and data category to export."
            )
        }
    }

    // MARK: - Section: Info Callout

    private var infoCalloutSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                    .frame(width: 24)
                Text("A telemetry feature must be opted-in before data can be exported. Enable DEX or ZeroTrust in DEX Opt-In first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Section: Export Button

    private var exportButtonSection: some View {
        Section {
            Button {
                self.performExport()
            } label: {
                HStack {
                    Spacer()
                    if self.isExporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.isExporting)
        }
    }

    // MARK: - Section: Results

    private var resultsSection: some View {
        Section {
            if let json = self.exportedJSON {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button {
                            UIPasteboard.general.string = json
                            self.toastMessage = "Copied to clipboard ✓"
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                    ScrollView {
                        Text(json)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .frame(minHeight: 120)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } else {
                Text("No export yet. Tap Export to fetch telemetry data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        } header: {
            SectionHeaderView(
                title: "Results",
                systemImage: "doc.text.magnifyingglass",
                description: "Exported telemetry data in the selected format."
            )
        }
    }

    // MARK: - Export Logic

    private func performExport() {
        self.isExporting = true
        let telemetryType = self.selectedTelemetryType.sdkType

        // WS1Intelligence.exportTelemetryFeatureData(telemetryType:of:with:completion:)
        // Asynchronously exports telemetry data for opted-in features (DEX, ZeroTrust).
        // Only DEX and ZeroTrust are supported for export; Application is NOT supported.
        // Pass WS1TelemetryTypeAll to export all enabled telemetry (DEX and/or ZeroTrust).
        // A feature must be opted-in before data can be queried; otherwise result may be nil or stale.
        // Completion may be called on a background thread; dispatch to main for UI updates.
        WS1Intelligence.exportTelemetryFeatureData(telemetryType, of: self.selectedFormat, with: self.selectedCategory) { [self] result in
            Task { @MainActor in
                self.isExporting = false
                let data = result
                if !data.isEmpty {
                    self.exportedJSON = self.formatJSONIfNeeded(data)
                    self.toastMessage = "Export complete ✓"
                } else {
                    self.exportedJSON = nil
                    self.toastMessage = "No data — enable DEX or ZeroTrust opt-in first"
                }
            }
        }
    }

    /// Attempts to pretty-print JSON if the string is valid JSON; otherwise returns as-is.
    private func formatJSONIfNeeded(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .prettyPrinted]),
              let str = String(data: formatted, encoding: .utf8) else {
            return raw
        }
        return str
    }
}

// MARK: - ExportTelemetryType

/// Wrapper for telemetry types supported by the export API.
/// Export supports DEX and ZeroTrust only. Application is NOT supported.
private enum ExportTelemetryType: CaseIterable {
    case DEX
    case zeroTrust

    var label: String {
        switch self {
        case .DEX: return "DEX"
        case .zeroTrust: return "ZeroTrust"
        }
    }

    var sdkType: WS1TelemetryType {
        switch self {
        case .DEX: return .DEX
        case .zeroTrust: return .zeroTrust
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TelemetryExportView()
            .environment(IntelSDKManager())
    }
}
