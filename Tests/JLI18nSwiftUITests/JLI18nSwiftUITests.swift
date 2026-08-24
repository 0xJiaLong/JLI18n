import XCTest
import JLI18n
import JLI18nSwiftUI

final class JLI18nSwiftUITests: XCTestCase {
    @MainActor
    func testLocalizedTextCanBeCreated() {
        let view = LocalizedText(key: "home.title")
        _ = view
    }
}
