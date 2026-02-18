//
//  IntelSDKSampleAppApp.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import SwiftUI

@main
struct IntelSDKSampleAppApp: App {

    // IntelSDKManager is created once here and injected into the environment so that every
    // view in the hierarchy can access the same shared instance via @Environment(IntelSDKManager.self).
    @State private var sdkManager = IntelSDKManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(self.sdkManager)
        }
    }
}
