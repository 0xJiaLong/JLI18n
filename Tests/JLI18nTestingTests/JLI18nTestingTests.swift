import XCTest
import JLI18n
@testable import JLI18nTesting

final class JLI18nTestingTests: XCTestCase {
    func testInMemoryProviderAndCollector() {
        let provider = InMemoryLocalizationProvider(values: ["en": ["home.title": "Home"]])
        XCTAssertEqual(provider.localizedString(for: "home.title", locale: "en"), "Home")
        let collector = DiagnosticCollector()
        let diagnostic = LocalizationDiagnostic(kind: .missingKey, key: "missing", locale: "en", message: "missing")
        collector.record(diagnostic)
        XCTAssertEqual(collector.diagnostics, [diagnostic])
    }
}
