//
//  IntelSDKManager.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import WS1IntelligenceSDK


// MARK: - IntelSDKManager

/// Central state manager for the WS1 Intelligence SDK.
///
/// Owns all pre-init configuration mirrors (editable only before `enableSDK()` is called)
/// and all post-init runtime state.
/// Injected into the SwiftUI environment from the app entry point so every view can read the same shared instance.
///
@Observable
final class IntelSDKManager: WS1IntelligenceSDK.WS1UEMDataDelegate {
    // MARK: Pre-Init Configuration Mirrors
    // These properties mirror the fields of WS1Config. They are editable on the Dashboard
    // before the SDK is initialized. Once enableSDK() is called, WS1Config is frozen and
    // changing these properties has no effect on the running SDK for the current session.

    /// The Intelligence App ID entered by the user. Defaults to empty; the UI shows
    /// "YOUR_APP_ID_HERE" as a placeholder. Never hardcoded — always entered at runtime.
    var appID: String = ""

    /// Mirror of WS1Config.enableServiceMonitoring.
    /// Controls whether the SDK automatically captures all network traffic.
    /// When false, no network instrumentation is installed and no APM data is collected.
    /// Default: true
    var enableServiceMonitoring: Bool = true

    /// Mirror of WS1Config.monitorNSURLSession.
    /// Controls whether NSURLSession-based requests are automatically intercepted.
    /// Requires enableServiceMonitoring = true to have any effect.
    /// Default: true
    var monitorNSURLSession: Bool = true

    /// Mirror of WS1Config.monitorNSURLConnection.
    /// Controls whether legacy NSURLConnection-based requests are automatically intercepted.
    /// Requires enableServiceMonitoring = true to have any effect.
    /// Default: true
    var monitorNSURLConnection: Bool = true

    /// Mirror of WS1Config.monitorWKWebView.
    /// Controls whether WKWebView page loads are captured. Disabled by default because
    /// enabling it triggers WKWebView class initialization (background thread) as a side
    /// effect even in apps that never use web views.
    /// Default: false
    var monitorWKWebView: Bool = false

    /// Mirror of WS1Config.allowsCellularAccess.
    /// When false, the SDK queues all telemetry and only uploads on Wi-Fi. (This is applicable to non-DEX telemetry only)
    /// Default: true
    var allowsCellularAccess: Bool = true

    /// Mirror of WS1Config.enableMachExceptionHandling.
    /// Enables capture of MACH-level exceptions (e.g. stack overflows) in addition to
    /// signal-based crashes. Has no effect when a debugger is attached.
    /// Disable if another framework already installs a MACH exception handler.
    /// Default: true
    var enableMachExceptionHandling: Bool = true

    /// Mirror of WS1Config.entitlements.
    /// Entitlements the app holds that affect DEX data collection. The SDK uses these
    /// to unlock additional telemetry (e.g. Bluetooth state, Wi-Fi SSID, multicast).
    /// Must declare only entitlements the app binary actually has; declaring extras has no
    /// negative effect but omitting them means the SDK cannot collect that data.
    ///
    /// Stored as string keys ("bluetooth", "wifi_info", "multicast") rather than
    /// WS1Entitlement objects because WS1Entitlement factory methods return a new NSObject
    /// instance on every call, making Set containment checks unreliable. Keys are mapped
    /// to WS1Entitlement instances only at the point of calling config.entitlements.
    var selectedEntitlementKeys: Set<String> = []

    // MARK: UEM Delegate Fields (Pre-Init)
    // These values populate the WS1UEMDataDelegate before enableSDK() is called.
    // -> These details can be populated post `enableSDK()` as well but the delegate should be registered pre-enableSDK()
    // They publish device-level UEM attributes to the Intelligence backend. In a real UEM-managed deployment
    // these would come from Managed App Configuration (`com.apple.configuration.managed`); here they are entered manually.
    //
    // `deviceUUID` (26.2.0+): Workspace ONE UEM global device identifier from the `intelsdk_device_uuid` KVP
    // (e.g. EMM Managed Access value `{DeviceUuId}`). Used in unauthenticated Intelligence mode to associate
    // telemetry with the UEM device record. Read in production with `WS1UEMAttributeKeys.intelSDKDeviceUUID()`.

    var uemSerialNumber: String = ""
    var uemDeviceUDID: String = ""
    /// UEM global device UUID (`intelsdk_device_uuid`); distinct from `deviceUDID`.
    var uemDeviceUUID: String = ""
    var uemUsername: String = ""

    // MARK: Post-Init Runtime State
    // Populated after enableSDK() returns. Views gate their interactive content on isInitialized.

    /// True once WS1Intelligence.enable(withAppID:config:) has been called successfully.
    /// Drives the two-phase UX: pre-init config form vs. post-init status dashboard.
    var isInitialized: Bool = false

    /// The SDK-generated per-device UUID. Available after initialization.
    /// Useful for correlating crash reports and telemetry to a specific device in the portal.
    var userUUID: String = ""

    /// True if the SDK detected a crash on the previous app session.
    /// Populated after initialization by reading WS1Intelligence.didCrashOnLastLoad().
    var crashedOnLastLoad: Bool = false

    /// The name of the crash recorded in the previous session (e.g. "SIGABRT", "EXC_BAD_ACCESS").
    /// Populated by the WS1NotificationDidCrashOnLastLoad notification observer registered in init().
    /// Nil if the app did not crash on the last load or the notification has not yet fired.
    var lastCrashName: String?

    /// A human-readable description of why the crash occurred.
    /// Populated by the WS1NotificationDidCrashOnLastLoad notification observer registered in init().
    var lastCrashReason: String?

    /// The date/time string of when the crash occurred, as reported by the SDK.
    /// Populated by the WS1NotificationDidCrashOnLastLoad notification observer registered in init().
    var lastCrashDate: String?

    // MARK: Post-Init Mutable Settings

    /// Current SDK logging verbosity level. Can be changed at any time after init.
    /// Defaults to .warning; the Dashboard exposes a picker to change this live.
    var loggingLevel: WS1IntelligenceLoggingLevel = .warning

    // MARK: Private

    // Retained token for the WS1NotificationDidCrashOnLastLoad observer.
    // Registered in init() — before enableSDK() is called — so the notification cannot
    // fire and be missed in a race between enable() and observer registration.
    private var _crashObserver: NSObjectProtocol?

    // MARK: Initialization

    init() {
        // NotificationCenter.default.addObserver(forName: .WS1NotificationDidCrashOnLastLoad, ...)
        // The SDK posts WS1NotificationDidCrashOnLastLoad on the main queue during the enable()
        // call if it detects that the app crashed in the previous session. The notification's
        // userInfo carries the crash name, reason, and date string, providing richer context
        // than didCrashOnLastLoad() alone.
        // NOTE - Crash reason can either be a reason or crash code.
        //
        // We register this observer here — in init() — rather than inside enableSDK(), because
        // the notification can fire synchronously during enable(). Registering after the enable()
        // call would create a race condition where the notification fires before the handler is
        // in place, resulting in the crash details never being captured.
        //
        // Constraint: The observer fires at most once per app session. The retained token in
        // _crashObserver keeps the block alive for the duration of the session.
        self._crashObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name(WS1NotificationDidCrashOnLastLoad),
            object: nil,
            queue: .main) { [weak self] notification in
                self?.lastCrashName   = notification.userInfo?[WS1NotificationCrashNameKey]   as? String
                self?.lastCrashReason = notification.userInfo?[WS1NotificationCrashReasonKey] as? String
                self?.lastCrashDate   = notification.userInfo?[WS1NotificationCrashDateKey]   as? String
        }
    }

    // MARK: SDK Initialization

    /// Builds a WS1Config from the current pre-init mirrors, sets the UEM
    /// delegate, then calls WS1Intelligence.enable(withAppID:config:).
    ///
    /// This method must be called at most once per app session. The SDK does not support
    /// re-initialization within the same process lifetime. After this returns, all WS1Config
    /// properties are frozen; any subsequent changes to the mirrors above have no effect
    /// until the app is restarted.
    ///
    /// - Returns: An error string if the App ID is empty, nil on success.
    @discardableResult
    func enableSDK() -> String? {
        guard !self.appID.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "App ID is required. Enter your Intelligence App ID and try again."
        }

        guard self.isInitialized == false else {
            return "SDK is already initialized!"
        }

        // WS1Config.default()
        // Creates a new configuration object pre-populated with the SDK's recommended defaults.
        // All properties must be set on this object BEFORE passing it to enable(). Changes made
        // to the config object after enable() is called are silently ignored by the SDK.
        let config = WS1Config.default()

        // config.enableServiceMonitoring
        // Master switch for automatic network traffic capture. When false, the SDK installs no
        // network instrumentation at all; monitorNSURLSession and monitorNSURLConnection become
        // irrelevant. Set before enable() — immutable afterwards.
        config.enableServiceMonitoring = self.enableServiceMonitoring

        // config.monitorNSURLSession
        // When true, the SDK swizzles NSURLSession to intercept and measure all HTTP/HTTPS
        // requests made through the standard URL loading system. Requires enableServiceMonitoring.
        // Set before enable() — immutable afterwards.
        config.monitorNSURLSession = self.monitorNSURLSession

        // config.monitorNSURLConnection
        // When true, the SDK intercepts legacy NSURLConnection requests. Most modern apps use
        // NSURLSession instead, but enabling this ensures full coverage. Requires enableServiceMonitoring.
        // Set before enable() — immutable afterwards.
        config.monitorNSURLConnection = self.monitorNSURLConnection

        // config.monitorWKWebView
        // When true, the SDK captures WKWebView page load events. Has a side effect of triggering
        // WKWebView class initialization (spawning a background thread) even if the app never opens
        // a web view. Disabled by default; only enable if the app actually uses WKWebView.
        // Set before enable() — immutable afterwards.
        config.monitorWKWebView = self.monitorWKWebView

        // config.allowsCellularAccess
        // When false, all SDK telemetry uploads (non-DEX events) are deferred until a Wi-Fi connection is available.
        // Useful for low-bandwidth or metered-data environments. Does not affect data collection,
        // only transmission. Set before enable() — immutable afterwards.
        config.allowsCellularAccess = self.allowsCellularAccess

        // config.enableMachExceptionHandling
        // When true, the SDK installs a MACH exception handler in addition to the POSIX signal
        // handler, enabling capture of additional crash classes such as stack overflows.
        // Automatically disabled when a debugger is attached to avoid conflicts.
        // Disable if another framework (e.g. a custom crash reporter) already owns MACH exceptions.
        // Set before enable() — immutable afterwards.
        config.enableMachExceptionHandling = self.enableMachExceptionHandling

        // config.entitlements
        // Declares the system-level entitlements the app binary holds. The SDK uses these flags
        // to enable the corresponding DEX data sources (Bluetooth state, Wi-Fi SSID, multicast
        // group membership). Only declare entitlements that are actually present in the app's
        // provisioning profile; the SDK does not verify them independently.
        // Set before enable() — immutable afterwards.
        //
        // WS1Entitlement objects are created here (once, at init time) from the string keys
        // stored in selectedEntitlementKeys.
        var entitlements: [WS1Entitlement] = []
        if self.selectedEntitlementKeys.contains("bluetooth") { entitlements.append(.bluetooth()) }
        if self.selectedEntitlementKeys.contains("wifi_info") { entitlements.append(.wifi_info()) }
        if self.selectedEntitlementKeys.contains("multicast") { entitlements.append(.multicast()) }
        config.entitlements = entitlements

        // WS1Intelligence.setLoggingLevel(_:)
        // Controls the verbosity of the SDK's internal log output to Xcode console.
        // Applied before enable() to match the default level stored in the manager.
        // Can be changed again at any time post-init. Levels: .silent, .error, .warning,
        // .info, .debug. Use .debug during development, .warning or .silent in production.
        WS1Intelligence.setLoggingLevel(self.loggingLevel)

        // WS1Intelligence.setUEMProviderDelegate(_:)
        // Supplies UEM device attributes (serial number, device UDID, device UUID, username) to the SDK so
        // that DEX telemetry can be correlated with the device record in the UEM console.
        // Must be called BEFORE enable(). In production, implement this delegate in the component
        // that reads NSUserDefaults ManagedAppConfig keys populated by the UEM SDK.
        // Constraint: the delegate object must stay alive for the duration of the session;
        // the SDK holds a weak reference internally.
        WS1Intelligence.setUEMProviderDelegate(self)

        // WS1Intelligence.enable(withAppID:config:)
        // Initializes the SDK for this app session. This is a one-time, irreversible call —
        // the SDK cannot be re-initialized or shut down within the same process lifetime.
        // After this returns, WS1Config is frozen. All crash handlers, network interceptors,
        // and telemetry pipelines are installed at this point.
        //
        // Interoperability initialization order (if using multiple APM/crash SDKs):
        //   1. AppDynamics  — must be initialized BEFORE Intelligence SDK
        //   2. Intelligence SDK  — this call
        //   3. Crashlytics  — must be initialized AFTER Intelligence SDK
        //   4. New Relic    — must be initialized AFTER Intelligence SDK
        //
        // To locate or create your App ID, see:
        // https://docs.omnissa.com/bundle/Intelligence/page/IntelIntelligenceSDKApps.html
        //
        // Alternatively, set the "WS1IntelligenceAppID" key in Info.plist and call
        // WS1Intelligence.enable() with no arguments.
        WS1Intelligence.enable(withAppID: self.appID, config: config)

        // Mark the SDK as running and hydrate post-init state.
        self.isInitialized = true

        // WS1Intelligence.getUserUUID()
        // Returns the SDK-generated stable per-app UUID (This is a randomly generated ID which is reset on uninstall and re-install).
        // Only valid after enable() has been called.
        self.userUUID = WS1Intelligence.getUserUUID()

        // WS1Intelligence.didCrashOnLastLoad()
        // Returns true if the SDK recorded a crash during the previous app session.
        // Only meaningful immediately after enable(); the value does not change during the
        // session. Use this to surface a crash indicator on the Dashboard and to trigger
        // any first-launch crash recovery logic in a real app.
        self.crashedOnLastLoad = WS1Intelligence.didCrashOnLastLoad()

        return nil
    }

    /// Updates the SDK logging level to the current value of `loggingLevel`.
    func applyLoggingLevel() {
        // WS1Intelligence.setLoggingLevel(_:)
        // Updates the SDK's internal log verbosity at runtime. This is one of the few SDK
        // settings that can be changed after enable() without restarting the app.
        // The new level takes effect immediately for all subsequent SDK log output.
        WS1Intelligence.setLoggingLevel(self.loggingLevel)
    }
}

extension IntelSDKManager {

    @objc var serialNumber: String? {
        return self.uemSerialNumber
    }

    @objc var deviceUDID: String? {
        return self.uemDeviceUDID
    }

    @objc var deviceUUID: String? {
        return self.uemDeviceUUID
    }

    @objc var username: String? {
        return self.uemUsername
    }
}
