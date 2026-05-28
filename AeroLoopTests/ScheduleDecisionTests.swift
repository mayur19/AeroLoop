import Foundation
import XCTest
@testable import AeroLoop

final class ScheduleDecisionTests: XCTestCase {

    private let battery = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
    private let night = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!
    private let day = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!

    func testBatteryTakesPrecedenceOverDayAndNight() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: true,
            isDarkMode: true,
            batteryPlaylistId: battery.uuidString,
            nightPlaylistId: night.uuidString,
            dayPlaylistId: day.uuidString
        )
        XCTAssertEqual(id, battery)
    }

    func testDarkModeSelectsNight() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: false,
            isDarkMode: true,
            batteryPlaylistId: nil,
            nightPlaylistId: night.uuidString,
            dayPlaylistId: day.uuidString
        )
        XCTAssertEqual(id, night)
    }

    func testLightModeSelectsDay() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: false,
            isDarkMode: false,
            batteryPlaylistId: nil,
            nightPlaylistId: night.uuidString,
            dayPlaylistId: day.uuidString
        )
        XCTAssertEqual(id, day)
    }

    func testBatteryFallsThroughWhenNoBatteryPlaylistSet() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: true,
            isDarkMode: true,
            batteryPlaylistId: nil,
            nightPlaylistId: night.uuidString,
            dayPlaylistId: day.uuidString
        )
        XCTAssertEqual(id, night, "Without a battery playlist, dark mode should fall through to night")
    }

    func testDarkModeWithoutNightPlaylistReturnsNil() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: false,
            isDarkMode: true,
            batteryPlaylistId: nil,
            nightPlaylistId: nil,
            dayPlaylistId: day.uuidString
        )
        XCTAssertNil(id, "Dark mode must not fall back to the day playlist")
    }

    func testInvalidUUIDStringIsIgnored() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: true,
            isDarkMode: true,
            batteryPlaylistId: "not-a-valid-uuid",
            nightPlaylistId: night.uuidString,
            dayPlaylistId: day.uuidString
        )
        XCTAssertEqual(id, night, "An unparseable battery ID should be skipped")
    }

    func testNoPlaylistsConfiguredReturnsNil() {
        let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: true,
            isDarkMode: false,
            batteryPlaylistId: nil,
            nightPlaylistId: nil,
            dayPlaylistId: nil
        )
        XCTAssertNil(id)
    }
}
