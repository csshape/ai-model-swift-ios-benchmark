import Foundation

struct DisplayError: Error, Equatable {
    let message: String
    let recoverySuggestion: String
}

enum LoadableState<Value> {
    case idle
    case loading
    case content(Value)
    case error(DisplayError)

    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
}
