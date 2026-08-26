#if canImport(AlarmKit)
import AlarmKit
import JLI18n
import JLI18nTesting
import SwiftUI
import XCTest

@available(iOS 26, *)
final class AlarmKitIntegrationTests: XCTestCase {
    func testManagerResourceInitializesAlarmButton() async {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en", "zh-Hans"],
            fallbackLocale: "en",
            diagnostics: .init(mode: .reportOnly)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [InMemoryLocalizationProvider(values: [:])]
        )
        await manager.setLocale("zh-Hans")

        let resource = await manager.resource(for: "alarm.button.stop")
        let button = AlarmButton(
            text: resource,
            textColor: .white,
            systemImageName: "stop.fill"
        )

        XCTAssertEqual(button.text.key, "alarm.button.stop")
        XCTAssertEqual(button.text.locale.identifier, "zh-Hans")
    }
}
#endif
