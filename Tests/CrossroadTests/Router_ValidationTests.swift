import Foundation
import XCTest
import Crossroad

final class Router_ValidationTests: XCTestCase {
    private let customURLScheme: LinkSource = .customURLScheme("pokedex")
    private let universalLink: LinkSource = .universalLink(URL(string: "https://my-awesome-pokedex.com")!)
    private let unknownCustomURLScheme: LinkSource = .customURLScheme("unknown")

    func testValidateForInvalidPattern() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.customURLScheme, self.universalLink]) { route in
                route("/////aaaaaa/////") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Pattern string '/////aaaaaa/////' is invalid."###)
        }
    }

    func testValidateForUnknownLinkSource() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.customURLScheme, self.universalLink]) { route in
                route("/hoge/fuga", accepting: .only(for: unknownCustomURLScheme)) { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Unknown link sources [unknown://] is registered"###)
        }
    }

    func testValidateForDuplicatedRoute() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.customURLScheme, self.universalLink]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }

                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Route definition for /hoge/fuga (accepting any) is duplicated"###)
        }
    }

    func testValidateForDuplicatedRouteWithAcceptPolicy() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.customURLScheme, self.universalLink]) { route in
                route("/hoge/fuga", accepting: .only(for: customURLScheme)) { _ in
                    return true
                }

                route("/hoge/fuga", accepting: .only(for: customURLScheme)) { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Route definition for /hoge/fuga (accepting only(for: Set([pokedex://]))) is duplicated"###)
        }
    }

    func testValidateForDuplicatedRouteWithSamePathAndNotIntercectedAcceptPolicy() throws {
        XCTAssertNoThrow(
            try SimpleRouter(accepting: [self.customURLScheme, self.universalLink]) { route in
                route("/hoge/fuga", accepting: .only(for: customURLScheme)) { _ in
                    return true
                }

                route("/hoge/fuga", accepting: .only(for: universalLink)) { _ in
                    return true
                }
            }
        )
    }

    func testValidateForUnknownSchemeContainsPattern() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.universalLink]) { route in
                route("pokedex://hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Pattern 'pokedex://hoge/fuga' contains invalid link source 'pokedex://'."###)
        }
    }

    func testValidateForAcceptingUnknownScheme() throws {
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [self.universalLink, self.universalLink]) { route in
                route("pokedex://hoge/fuga", accepting: .only(for: universalLink)) { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Pattern 'pokedex://hoge/fuga' contains invalid link source 'pokedex://'."###)
        }
    }

    func testValidateForUniversalLinkURLIsInvalid() throws {
        let invalidUniversalLink: LinkSource = .universalLink(URL(string: "/invalid")!)
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [invalidUniversalLink]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Link source '/invalid' must be absolute URL."###)
        }
    }

    func testValidateForUniversalLinkURLIsFileURL() throws {
        let invalidUniversalLink: LinkSource = .universalLink(URL(string: "file://fileURL")!)
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [invalidUniversalLink]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Link source 'file://fileURL' must be absolute URL."###)
        }
    }

    func testValidateForUniversalLinkURLContainsPath() throws {
        let invalidUniversalLink: LinkSource = .universalLink(URL(string: "https://my-awesome-pokedex.com/path")!)
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [invalidUniversalLink]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Link source 'https://my-awesome-pokedex.com/path' should not contain any pathes."###)
        }
    }

    func testValidateForUniversalLinkURLContainsSlash() throws {
        let invalidUniversalLink: LinkSource = .universalLink(URL(string: "https://my-awesome-pokedex.com/")!)
        XCTAssertNoThrow(
            try SimpleRouter(accepting: [invalidUniversalLink]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        )
    }

    func testValidateForSchemeIsWellKnown() throws {
        let wellKnownScheme: LinkSource = .customURLScheme("https")
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [wellKnownScheme]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Link source 'https' should not be well known."###)
        }
    }

    func testValidateForSchemeContainsSlash() throws {
        let wellKnownScheme: LinkSource = .customURLScheme("poke/dex")
        XCTAssertThrowsError(
            try SimpleRouter(accepting: [wellKnownScheme]) { route in
                route("/hoge/fuga") { _ in
                    return true
                }
            }
        ) { error in
            let error = error as? LocalizedError
            XCTAssertEqual(error?.errorDescription, ###"Link source 'poke/dex' contains invalid characters."###)
        }
    }
}
