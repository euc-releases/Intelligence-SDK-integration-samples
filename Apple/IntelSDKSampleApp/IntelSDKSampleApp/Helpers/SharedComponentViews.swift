//
//  SharedComponentViews.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// A reusable info row used throughout the app to present a labelled piece of information
/// with a leading SF Symbol icon, a bold title, and a descriptive body line.
struct InfoRowView: View {

    let icon: String
    let color: Color
    let title: String
    let infoBody: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.icon)
                .foregroundStyle(self.color)
                .font(.title3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)
                Text(self.infoBody)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A monospaced code snippet block used throughout the app to illustrate SDK API calls.
///
/// The `label` parameter controls the header text shown above the snippet and defaults
/// to `"SDK calls"`. Pass `"SDK call"` (singular) when the snippet demonstrates a single API.
struct CodeSnippetView: View {

    let code: String
    var label: String = "SDK calls"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(self.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(self.code)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

#Preview {
    List {
        InfoRowView(icon: "wifi", color: .blue, title: "Auto-capture enabled",
                    infoBody: "All NSURLSession traffic is automatically captured by the SDK.")
        CodeSnippetView(code: "WS1Intelligence.leaveBreadcrumb(\"user tapped checkout\")")
        CodeSnippetView(code: "WS1Intelligence.logError(error)", label: "SDK call")
    }
}
