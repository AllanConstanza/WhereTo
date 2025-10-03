//
//  LocationManager.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/14/25.

import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var status: CLAuthorizationStatus = .notDetermined
    @Published var location: CLLocation?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50 
    }
    
    func start() {
        manager.requestWhenInUseAuthorization()
    }
    
    func refresh() {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            location = last
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    var statusText: String {
            switch status {
            case .notDetermined: return "Not determined"
            case .restricted:    return "Restricted"
            case .denied:        return "Denied"
            case .authorizedAlways:     return "Authorized (Always)"
            case .authorizedWhenInUse:  return "Authorized (When In Use)"
            @unknown default:          return "Unknown"
            }
        }
    
}
