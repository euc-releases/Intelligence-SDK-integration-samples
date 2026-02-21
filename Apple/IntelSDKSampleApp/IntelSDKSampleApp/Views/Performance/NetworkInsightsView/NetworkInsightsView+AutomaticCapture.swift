//
//  NetworkInsightsView+AutomaticCapture.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI


extension NetworkInsightsView {

    // MARK: - Section: Automatic Capture Demo

    var automaticCaptureSection: some View {
        Section {
            self.infoRow(
                icon: "wand.and.stars",
                color: .blue,
                title: "Automatic Capture",
                body: "When service monitoring is enabled, the SDK automatically captures all NSURLSession and NSURLConnection network requests made by the app. No manual logging is needed for these."
            )

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Async/Await APIs Not Supported")
                        .font(.headline)
                    Text("**Swift async/await URLSession APIs are not automatically captured by the SDK.** Log async/await requests manually via `logNetworkRequest`.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            // "Fire Sample Request" — success path
            Button {
                self.fireSampleRequest(label: "Sample GET", urlString: "https://httpbin.org/get", slotKey: "success")
            } label: {
                HStack {
                    Spacer()
                    if self.isFiringSuccess {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("Firing…")
                            .fontWeight(.semibold)
                    } else {
                        Label("Fire Sample Request", systemImage: "paperplane.fill")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(self.isFiringSuccess || self.isFiringFailure)

            // "Fire Failing Request" — error path
            Button {
                self.fireSampleRequest(label: "Failing Request", urlString: "https://this-host-does-not-exist.invalid", slotKey: "failure")
            } label: {
                HStack {
                    Spacer()
                    if self.isFiringFailure {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("Firing…")
                            .fontWeight(.semibold)
                    } else {
                        Label("Fire Failing Request", systemImage: "xmark.icloud")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(self.isFiringSuccess || self.isFiringFailure)
            .foregroundStyle(.orange)

            self.codeSnippetView("""
                // Use completion-handler form — SDK captures this automatically.
                // ⚠️ async/await URLSession APIs are NOT captured automatically.
                URLSession.shared.dataTask(with: url) { data, response, error in
                    // SDK has already recorded this request automatically.
                }.resume()
                """)

            ForEach(self.sampleResults.reversed()) { result in
                self.requestResultRow(result)
            }

        } header: {
            SectionHeaderView(
                title: "Automatic Capture Demo",
                systemImage: "bolt.shield",
                description: "Fire a real network request and see how the SDK captures it with zero manual code."
            )
        } footer: {
            Text("Requests above were automatically captured by the SDK. No logNetworkRequest() call was made.")
                .font(.caption)
        }
    }

    
    /// Fires a URLSession data task to the given URL, measures latency, and records the result locally.
    /// The SDK automatically captures this request because service monitoring is enabled — no
    /// manual logNetworkRequest() call is made here.
    private func fireSampleRequest(label: String, urlString: String, slotKey: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        if slotKey == "success" {
            self.isFiringSuccess = true
        } else {
            self.isFiringFailure = true
        }

        let start = Date()

        // URLSession.shared.dataTask(with:completionHandler:)
        // A completion-handler based NSURLSession data task. When service monitoring is enabled,
        // the WS1 Intelligence SDK automatically intercepts this call at the Objective-C level
        // and records the URL, HTTP status code, bytes transferred, and latency — no additional
        // code is required from the developer for automatic capture.
        //
        // ⚠️ IMPORTANT: Swift async/await URLSession APIs (e.g. URLSession.shared.data(from:))
        // are NOT automatically captured by the SDK. They bypass the Objective-C interception
        // points the SDK relies on. For async/await networking, use
        // WS1Intelligence.logNetworkRequest(...) to log the request manually.
        URLSession.shared.dataTask(with: url) { data, response, err in
            let httpResponse = response as? HTTPURLResponse

            let latencyMs = Date().timeIntervalSince(start) * 1000
            let result = SampleRequestResult(
                label: label,
                url: urlString,
                statusCode: httpResponse?.statusCode,
                bytesReceived: data?.count,
                latencyMs: latencyMs,
                error: err?.localizedDescription,
                firedAt: start
            )

            DispatchQueue.main.async {
                self.sampleResults.append(result)
                self.presentToast("Request captured by SDK automatically ✓")

                if slotKey == "success" {
                    self.isFiringSuccess = false
                } else {
                    self.isFiringFailure = false
                }
            }
        }.resume()
    }

    /// Displays the result of a sample auto-captured request.
    @ViewBuilder
    private func requestResultRow(_ result: SampleRequestResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.isSuccess ? .green : .red)
                    .font(.subheadline)
                Text(result.label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(result.firedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(result.url)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if result.isSuccess {
                HStack(spacing: 12) {
                    if let code = result.statusCode {
                        Label(String(code), systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if let bytes = result.bytesReceived {
                        Label("\(bytes) B", systemImage: "arrow.down.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let ms = result.latencyMs {
                        Label(String(format: "%.0f ms", ms), systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let err = result.error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            Text("Auto-captured by SDK — no logNetworkRequest() needed.")
                .font(.caption2)
                .foregroundStyle(.teal)
                .italic()
        }
        .padding(.vertical, 4)
    }
}
