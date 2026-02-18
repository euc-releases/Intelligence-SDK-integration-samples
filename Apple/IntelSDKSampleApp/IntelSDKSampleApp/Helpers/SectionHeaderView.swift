//
//  SectionHeaderView.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

/// A reusable section header used throughout the app to label feature sections in Forms and Lists.
///
/// Combines an SF Symbol icon, a bold title, and a descriptive sub-line so every section
/// communicates both its identity and its purpose at a glance. Used as the `header:` argument
/// of SwiftUI `Section` initializers.
struct SectionHeaderView: View {

    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: self.systemImage)
                    .foregroundStyle(Color.accentColor)
                Text(self.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Text(self.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.bottom, 2)
    }
}

#Preview {
    Form {
        Section {
            Text("Sample row")
        } header: {
            SectionHeaderView(
                title: "Network Monitoring",
                systemImage: "network",
                description: "Configure automatic capture of NSURLSession and NSURLConnection traffic."
            )
        }
    }
}
