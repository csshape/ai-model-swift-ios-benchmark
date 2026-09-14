import XCTest

/// Cooperative spin: yields the current task until `condition` holds.
///
/// It never sleeps and never touches the wall clock, so tests stay fast and stable — the
/// iteration budget only exists so a broken expectation fails instead of hanging.
@MainActor
func waitUntil(
    _ condition: () -> Bool,
    iterations: Int = 500,
    message: String = "Condition was never met",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<iterations {
        if condition() { return }
        await Task.yield()
    }
    XCTFail(message, file: file, line: line)
}
