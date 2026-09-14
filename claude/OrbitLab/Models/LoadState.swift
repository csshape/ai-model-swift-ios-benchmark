import Foundation

/// The three states every asynchronously loaded screen in OrbitLab can be in.
enum LoadState<Value> {
    case idle
    case loading
    case content(Value)
    case failed(LoadFailure)

    var value: Value? {
        if case let .content(value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var failure: LoadFailure? {
        if case let .failed(failure) = self { return failure }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}

/// A user presentable description of a failure plus the information needed to retry it.
struct LoadFailure: Equatable {
    let message: String
    let recoverySuggestion: String

    init(message: String, recoverySuggestion: String = "Pull to refresh or tap Retry.") {
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }

    init(error: Error) {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            self.message = description
            self.recoverySuggestion = localized.recoverySuggestion ?? "Pull to refresh or tap Retry."
        } else {
            self.message = error.localizedDescription
            self.recoverySuggestion = "Pull to refresh or tap Retry."
        }
    }
}
