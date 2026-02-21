//
//  NetworkInsightsView+ManualLogging.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI
import WS1IntelligenceSDK


extension NetworkInsightsView {

    // MARK: - Section: Manual Network Logging

    var manualLoggingSection: some View {
        Section {
            InfoRowView(
                icon: "square.and.pencil",
                color: .purple,
                title: "When to Use Manual Logging",
                infoBody: "Use manual logging for network libraries that do not use NSURLSession or NSURLConnection — for example, custom socket code, gRPC, or third-party frameworks that bypass the standard URL loading system."
            )

            Picker("HTTP Method", selection: self.$manualMethod) {
                ForEach(self.httpMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }

            HStack {
                Text("URL")
                Spacer()
                TextField("https://example.com/api", text: self.$manualURL)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(maxWidth: 220)
            }

            HStack {
                Text("Latency (ms)")
                Spacer()
                TextField("120", text: self.$manualLatencyMs)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text("Bytes Read")
                Spacer()
                TextField("2048", text: self.$manualBytesRead)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text("Bytes Sent")
                Spacer()
                TextField("512", text: self.$manualBytesSent)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text("Response Code")
                Spacer()
                TextField("200", text: self.$manualResponseCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text("Error (optional)")
                Spacer()
                TextField("None", text: self.$manualErrorDescription)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180)
            }

            Button {
                self.logManualRequest()
            } label: {
                HStack {
                    Spacer()
                    Label("Log Network Request", systemImage: "square.and.arrow.down.on.square")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(self.manualURL.trimmingCharacters(in: .whitespaces).isEmpty)

            CodeSnippetView(code: """
                // WS1Intelligence.logNetworkRequest(method:urlString:latency:bytesRead:bytesSent:responseCode:error:)
                // latency is a TimeInterval (seconds) — convert from ms.
                WS1Intelligence.logNetworkRequest(
                    "GET", urlString: "https://example.com/api",
                    latency: 0.120, bytesRead: 2048, bytesSent: 512,
                    responseCode: 200, error: nil)
                """)

            ForEach(self.manualLog.reversed()) { entry in
                self.manualLogRow(entry)
            }

        } header: {
            SectionHeaderView(
                title: "Manual Network Logging",
                systemImage: "square.and.pencil.circle",
                description: "Manually report a network event for libraries that bypass NSURLSession/NSURLConnection."
            )
        } footer: {
            Text("The latency field is in milliseconds here for convenience — the SDK API accepts seconds (TimeInterval).")
                .font(.caption)
        }
    }

    /// Manually logs a network event to the SDK using the form fields.
    private func logManualRequest() {
        let latencyMs  = Int(self.manualLatencyMs)  ?? 0
        let bytesRead  = UInt(self.manualBytesRead)  ?? 0
        let bytesSent  = UInt(self.manualBytesSent)  ?? 0
        let respCode   = Int(self.manualResponseCode) ?? 0
        let urlTrimmed = self.manualURL.trimmingCharacters(in: .whitespaces)
        let errorDesc  = self.manualErrorDescription.trimmingCharacters(in: .whitespaces)

        let nsError: NSError? = errorDesc.isEmpty ? nil :
            NSError(domain: "com.sample.network", code: respCode,
                    userInfo: [NSLocalizedDescriptionKey: errorDesc])

        // WS1Intelligence.logNetworkRequest(method:urlString:latency:bytesRead:bytesSent:responseCode:error:)
        // Manually records a network event for network libraries that do not use NSURLSession or
        // NSURLConnection (e.g., raw socket connections, gRPC, third-party libraries that bypass
        // the standard URL loading system). The SDK cannot auto-capture these; manual logging is
        // the only way to include such requests in Network Insights on the portal.
        //
        // Parameters:
        //   - latency: TimeInterval (seconds) — convert from user-entered milliseconds here.
        //   - bytesRead: bytes in the response body.
        //   - bytesSent: bytes in the request body.
        //   - responseCode: standard HTTP status code; use 0 if the request never reached the server.
        //   - error: pass nil if the request succeeded; a non-nil NSError indicates a transport failure.
        WS1Intelligence.logNetworkRequest(
            self.manualMethod,
            urlString: urlTrimmed,
            latency: TimeInterval(latencyMs) / 1000.0,
            bytesRead: bytesRead,
            bytesSent: bytesSent,
            responseCode: respCode,
            error: nsError
        )

        let entry = ManualLogEntry(
            method: self.manualMethod,
            urlString: urlTrimmed,
            responseCode: respCode,
            latencyMs: latencyMs,
            bytesRead: bytesRead,
            bytesSent: bytesSent,
            errorDescription: errorDesc.isEmpty ? nil : errorDesc,
            loggedAt: Date()
        )
        self.manualLog.append(entry)
        self.presentToast("Network request logged manually ✓")
    }

    /// Displays a manually logged request entry.
    @ViewBuilder
    private func manualLogRow(_ entry: ManualLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(entry.method)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12), in: Capsule())
                    .foregroundStyle(.purple)
                Text(String(entry.responseCode))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.responseCode < 400 ? .green : .red)
                Spacer()
                Text(entry.loggedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(entry.urlString)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            HStack(spacing: 12) {
                Label("\(entry.latencyMs) ms", systemImage: "timer")
                Label("↓\(entry.bytesRead) B", systemImage: "arrow.down.circle")
                Label("↑\(entry.bytesSent) B", systemImage: "arrow.up.circle")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if let err = entry.errorDescription {
                Text("Error: \(err)")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            Text("Manually logged via logNetworkRequest()")
                .font(.caption2)
                .foregroundStyle(.purple)
                .italic()
        }
        .padding(.vertical, 4)
    }
}
