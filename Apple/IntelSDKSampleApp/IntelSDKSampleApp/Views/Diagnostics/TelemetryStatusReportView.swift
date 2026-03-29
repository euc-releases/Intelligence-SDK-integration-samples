//
//  TelemetryStatusReportView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI
import WS1IntelligenceSDK

/// Displays the JSON health-status report from `WS1Intelligence.generateStatusReport` (Intelligence SDK 26.2.0+).
struct TelemetryStatusReportView: View {

    @State private var reportText: String = ""
    @State private var isLoading: Bool = false
    @State private var lastError: String?
    @State private var toastMessage: String?

    var body: some View {
        Group {
            if self.isLoading && self.reportText.isEmpty {
                ProgressView("Generating report…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(self.displayBody)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle("Telemetry Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") {
                    self.loadReport()
                }
                .disabled(self.isLoading)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Copy") {
                    let text = self.reportText.isEmpty ? self.displayBody : self.reportText
                    UIPasteboard.general.string = text
                    self.toastMessage = "Copied to clipboard"
                }
            }
        }
        .onAppear {
            if self.reportText.isEmpty, !self.isLoading {
                self.loadReport()
            }
        }
        .toast(message: self.$toastMessage, duration: 1.5)
    }

    private var displayBody: String {
        if let lastError, self.reportText.isEmpty {
            return lastError
        }
        if self.reportText.isEmpty {
            return self.placeholderText
        }
        return self.reportText
    }

    private var placeholderText: String {
        "Tap Refresh to call WS1Intelligence.generateStatusReport. The SDK returns JSON describing initialization, configuration, permissions, and telemetry features."
    }

    private func loadReport() {
        self.isLoading = true
        self.lastError = nil

        WS1Intelligence.generateStatusReport { data in

            DispatchQueue.main.async {
                self.isLoading = false
                if let data, !data.isEmpty {
                    self.reportText = data
                } else {
                    self.reportText = ""
                    self.lastError = "No report returned (nil or empty). Try again after the SDK has fully initialized."
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TelemetryStatusReportView()
    }
}
