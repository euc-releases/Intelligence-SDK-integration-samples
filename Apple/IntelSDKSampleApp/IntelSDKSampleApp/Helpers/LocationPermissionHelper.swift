//
//  LocationPermissionHelper.swift
//  IntelSDKSampleApp
//
//  Copyright 2026 Omnissa, LLC.
//  SPDX-License-Identifier: BSD-2-Clause
//

import CoreLocation

/// Reusable helper that wraps `CLLocationManager` and exposes the current authorization
/// status as an observable property.
///
/// Used in the Dashboard's DEX Entitlements section to request When In Use authorization
/// when the `wifi_info` entitlement is selected (SSID/BSSID collection requires location
/// access). The same instance can be elevated to Always On authorization.
///
/// Conforms to `NSObject` to satisfy `CLLocationManagerDelegate` requirements.
@Observable
final class LocationPermissionHelper: NSObject, CLLocationManagerDelegate {

    // MARK: State

    /// The current Core Location authorization status. Starts at `.notDetermined` and
    /// is updated immediately after init and whenever the user changes the permission in Settings.
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: Private

    private let manager = CLLocationManager()

    // MARK: Init

    override init() {
        super.init()
        self.manager.delegate = self
    }

    // MARK: Permission Requests

    /// Requests When In Use authorization.
    ///
    /// Used by the DEX Wi-Fi Info entitlement row. The OS presents the system permission
    /// dialog only if `authorizationStatus` is `.notDetermined`; subsequent calls are no-ops.
    /// When In Use is sufficient for SSID/BSSID collection via NEHotspotNetwork.
    func requestWhenInUse() {
        self.manager.requestWhenInUseAuthorization()
    }

    /// Requests Always On authorization.
    ///
    /// Reserved for future features (e.g. continuous DEX location tracking) that require
    /// background location access. Must only be called after When In Use is already granted,
    /// otherwise iOS will ignore the request.
    func requestAlwaysOn() {
        self.manager.requestAlwaysAuthorization()
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
}
