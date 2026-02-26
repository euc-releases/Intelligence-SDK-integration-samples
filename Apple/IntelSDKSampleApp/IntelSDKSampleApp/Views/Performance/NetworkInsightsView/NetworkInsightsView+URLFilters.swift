//
//  NetworkInsightsView+URLFilters.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//


import SwiftUI
import WS1IntelligenceSDK


extension NetworkInsightsView {

    // MARK: - Section: URL Filters

    var urlFiltersSection: some View {
        Section {
            InfoRowView(
                icon: "nosign",
                color: .red,
                title: "URL Deny Filters",
                infoBody: "Any URL that contains the filter string (case-sensitive substring match) will not be reported to the Omnissa Intelligence backend at all. By default, query strings are stripped from all other reported URLs."
            )

            TextField("Filter token (e.g. \"analytics\")", text: self.$filterToken)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Picker("Filter Type", selection: self.$filterType) {
                Text("Deny").tag(WS1FilterType.deny)
                Text("Preserve Query").tag(WS1FilterType.preserveQuery)
                Text("Preserve Fragment").tag(WS1FilterType.preserveFragment)
                Text("Preserve Parameters").tag(WS1FilterType.preserveParameters)
                Text("Preserve All").tag(WS1FilterType.preserveAll)
            }

            Button {
                self.addFilter()
            } label: {
                HStack {
                    Spacer()
                    Label("Add Filter", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(self.filterToken.trimmingCharacters(in: .whitespaces).isEmpty)

            CodeSnippetView(code: """
                // WS1Intelligence.add(filter:)
                // Appends a URL filter at runtime. Matching uses case-sensitive substring.
                // Deny: URL is not reported to the Intelligence backend.
                // Preserve*: keeps the specified URL component that is otherwise stripped.
                WS1Intelligence.add(filter: WS1Filter(string: "analytics",
                                                      filterType: .deny))
                """)

            if self.filters.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No filters added yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                ForEach(self.filters) { filter in
                    HStack(spacing: 10) {
                        Image(systemName: filter.typeSystemImage)
                            .foregroundStyle(filter.type == .deny ? .red : .blue)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filter.token)
                                .font(.subheadline)
                            Text(filter.typeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(filter.addedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }

        } header: {
            SectionHeaderView(
                title: "URL Filters",
                systemImage: "line.3.horizontal.decrease.circle",
                description: "Control which URLs the SDK reports. Can be added at any time after initialization."
            )
        } footer: {
            Text("URL filters added here persist only for the current session. Filters cannot be removed once added to the SDK.")
                .font(.caption)
        }
    }

    /// Adds a URL filter to the SDK and records it locally.
    private func addFilter() {
        let token = self.filterToken.trimmingCharacters(in: .whitespaces)

        guard !token.isEmpty else {
            return
        }

        // WS1Intelligence.add(filter:)
        // Appends a URL filter to the SDK's active deny/preserve list at runtime.
        // Filters use case-sensitive substring matching against the full URL string.
        //
        // Filter types:
        //   .deny               — URLs containing the token are NOT reported to the Intelligence backend.
        //   .preserveQuery      — keeps the ?key=value query string (stripped by default).
        //   .preserveFragment   — keeps the #fragment identifier (stripped by default).
        //   .preserveParameters — keeps URL path parameters (stripped by default).
        //   .preserveAll        — keeps query, fragment, and parameters.
        //
        // Note: filters are additive and cannot be removed once applied for the current session.
        // Constraint: can be called at any time after enable() — unlike urlFilters on WS1Config,
        // which must be set before enable().
        let filter = WS1Filter(string: token, andFilterType: self.filterType)
        WS1Intelligence.add(filter)

        self.filters.append(FilterEntry(token: token, type: self.filterType, addedAt: Date()))
        self.filterToken = ""
        self.toastMessage = "Filter \"\(token)\" added ✓"
    }
}
