import Foundation

struct FormatToken: Sendable {
    let specifier: Character
    let position: Int?
}

struct FormatAnalysis: Sendable {
    let tokens: [FormatToken]
    let argumentCount: Int
}

enum FormatValidationResult: Sendable {
    case valid
    case missingArgument(expected: Int, actual: Int)
    case typeMismatch(index: Int, specifier: Character)
    case invalidFormat(String)
}

enum FormatParsingError: Error {
    case invalid(String)
}

enum FormatValidator {
    static func analyze(_ format: String) -> Result<FormatAnalysis, FormatParsingError> {
        let characters = Array(format)
        var tokens: [FormatToken] = []
        var index = 0
        var nextArgument = 1

        while index < characters.count {
            guard characters[index] == "%" else {
                index += 1
                continue
            }
            index += 1
            guard index < characters.count else { return .failure(.invalid("trailing percent")) }
            if characters[index] == "%" {
                index += 1
                continue
            }

            var position: Int?
            let start = index
            while index < characters.count, characters[index].isNumber { index += 1 }
            if index > start, index < characters.count, characters[index] == "$" {
                position = Int(String(characters[start..<index]))
                guard let position, position > 0 else { return .failure(.invalid("argument positions start at 1")) }
                index += 1
            } else {
                index = start
            }

            while index < characters.count, "-+ #0'".contains(characters[index]) { index += 1 }
            while index < characters.count, characters[index].isNumber || characters[index] == "*" { index += 1 }
            if index < characters.count, characters[index] == "." {
                index += 1
                while index < characters.count, characters[index].isNumber || characters[index] == "*" { index += 1 }
            }
            if index + 1 < characters.count, characters[index] == "h" || characters[index] == "l" {
                let length = characters[index]
                index += 1
                if index < characters.count, characters[index] == length { index += 1 }
            } else if index < characters.count, "Lzjt".contains(characters[index]) {
                index += 1
            }

            guard index < characters.count else { return .failure(.invalid("missing conversion specifier")) }
            let specifier = characters[index]
            guard "@diuoxXfFeEgGcsa".contains(specifier) else {
                return .failure(.invalid("unsupported conversion specifier"))
            }
            let resolvedPosition = position ?? nextArgument
            nextArgument = max(nextArgument, resolvedPosition + 1)
            tokens.append(FormatToken(specifier: specifier, position: position))
            index += 1
        }

        return .success(FormatAnalysis(tokens: tokens, argumentCount: max(0, nextArgument - 1)))
    }

    static func validate(_ format: String, arguments: [any CVarArg]) -> FormatValidationResult {
        switch analyze(format) {
        case .failure(.invalid(let message)): return .invalidFormat(message)
        case .success(let analysis):
            guard arguments.count >= analysis.argumentCount else {
                return .missingArgument(expected: analysis.argumentCount, actual: arguments.count)
            }
            for (index, token) in analysis.tokens.enumerated() {
                let argumentIndex = (token.position ?? index + 1) - 1
                guard argumentIndex < arguments.count else { continue }
                if !isCompatible(arguments[argumentIndex], with: token.specifier) {
                    return .typeMismatch(index: argumentIndex + 1, specifier: token.specifier)
                }
            }
            return .valid
        }
    }

    private static func isCompatible(_ argument: any CVarArg, with specifier: Character) -> Bool {
        switch specifier {
        case "@", "s": return argument is String || argument is NSString
        case "f", "F", "e", "E", "g", "G": return argument is Double || argument is Float
        case "d", "i", "u", "o", "x", "X":
            return argument is Int || argument is Int8 || argument is Int16 || argument is Int32 || argument is Int64
                || argument is UInt || argument is UInt8 || argument is UInt16 || argument is UInt32 || argument is UInt64
        case "c": return argument is CChar || argument is UInt8
        case "a": return argument is Double || argument is Float
        default: return false
        }
    }
}
