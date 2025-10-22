import Foundation

enum AIActionType: Codable {
    case edit(old: String, new: String)
    case rewrite(file: String, content: String)
    case insert(after: String, content: String)
    case terminal(command: String, reason: String)
    case search(pattern: String, reason: String)
    
    enum CodingKeys: String, CodingKey {
        case type, old, new, file, content, after, command, reason, pattern
    }
    
    enum ActionKind: String, Codable {
        case edit, rewrite, insert, terminal, search
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionKind.self, forKey: .type)
        
        switch type {
        case .edit:
            let old = try container.decode(String.self, forKey: .old)
            let new = try container.decode(String.self, forKey: .new)
            self = .edit(old: old, new: new)
        case .rewrite:
            let file = try container.decode(String.self, forKey: .file)
            let content = try container.decode(String.self, forKey: .content)
            self = .rewrite(file: file, content: content)
        case .insert:
            let after = try container.decode(String.self, forKey: .after)
            let content = try container.decode(String.self, forKey: .content)
            self = .insert(after: after, content: content)
        case .terminal:
            let command = try container.decode(String.self, forKey: .command)
            let reason = try container.decode(String.self, forKey: .reason)
            self = .terminal(command: command, reason: reason)
        case .search:
            let pattern = try container.decode(String.self, forKey: .pattern)
            let reason = try container.decode(String.self, forKey: .reason)
            self = .search(pattern: pattern, reason: reason)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .edit(let old, let new):
            try container.encode(ActionKind.edit, forKey: .type)
            try container.encode(old, forKey: .old)
            try container.encode(new, forKey: .new)
        case .rewrite(let file, let content):
            try container.encode(ActionKind.rewrite, forKey: .type)
            try container.encode(file, forKey: .file)
            try container.encode(content, forKey: .content)
        case .insert(let after, let content):
            try container.encode(ActionKind.insert, forKey: .type)
            try container.encode(after, forKey: .after)
            try container.encode(content, forKey: .content)
        case .terminal(let command, let reason):
            try container.encode(ActionKind.terminal, forKey: .type)
            try container.encode(command, forKey: .command)
            try container.encode(reason, forKey: .reason)
        case .search(let pattern, let reason):
            try container.encode(ActionKind.search, forKey: .type)
            try container.encode(pattern, forKey: .pattern)
            try container.encode(reason, forKey: .reason)
        }
    }
}

struct AIAction: Identifiable, Codable {
    let id: UUID
    let type: AIActionType
    let rawText: String
    
    init(id: UUID = UUID(), type: AIActionType, rawText: String) {
        self.id = id
        self.type = type
        self.rawText = rawText
    }
}

final class AIActionParser {
    static func parseActions(from response: String) -> (cleanResponse: String, actions: [AIAction]) {
        var actions: [AIAction] = []
        var cleanText = response
        
        let editPattern = #"<ACTION:EDIT>\s*<OLD>([\s\S]*?)</OLD>\s*<NEW>([\s\S]*?)</NEW>\s*</ACTION:EDIT>"#
        let rewritePattern = #"<ACTION:REWRITE>\s*<FILE>([\s\S]*?)</FILE>\s*<CONTENT>([\s\S]*?)</CONTENT>\s*</ACTION:REWRITE>"#
        let insertPattern = #"<ACTION:INSERT>\s*<AFTER>([\s\S]*?)</AFTER>\s*<CONTENT>([\s\S]*?)</CONTENT>\s*</ACTION:INSERT>"#
        let terminalPattern = #"<ACTION:TERMINAL>\s*<COMMAND>([\s\S]*?)</COMMAND>\s*<REASON>([\s\S]*?)</REASON>\s*</ACTION:TERMINAL>"#
        let searchPattern = #"<ACTION:SEARCH>\s*<PATTERN>([\s\S]*?)</PATTERN>\s*<REASON>([\s\S]*?)</REASON>\s*</ACTION:SEARCH>"#
        
        if let editRegex = try? NSRegularExpression(pattern: editPattern, options: []) {
            let matches = editRegex.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
            for match in matches.reversed() {
                guard match.numberOfRanges == 3,
                      let oldRange = Range(match.range(at: 1), in: response),
                      let newRange = Range(match.range(at: 2), in: response),
                      let fullRange = Range(match.range(at: 0), in: response) else { continue }
                
                let old = String(response[oldRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let new = String(response[newRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rawText = String(response[fullRange])
                
                actions.insert(AIAction(type: .edit(old: old, new: new), rawText: rawText), at: 0)
                cleanText = cleanText.replacingOccurrences(of: rawText, with: "")
            }
        }
        
        if let rewriteRegex = try? NSRegularExpression(pattern: rewritePattern, options: []) {
            let matches = rewriteRegex.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
            for match in matches.reversed() {
                guard match.numberOfRanges == 3,
                      let fileRange = Range(match.range(at: 1), in: response),
                      let contentRange = Range(match.range(at: 2), in: response),
                      let fullRange = Range(match.range(at: 0), in: response) else { continue }
                
                let file = String(response[fileRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rawText = String(response[fullRange])
                
                actions.insert(AIAction(type: .rewrite(file: file, content: content), rawText: rawText), at: 0)
                cleanText = cleanText.replacingOccurrences(of: rawText, with: "")
            }
        }
        
        if let insertRegex = try? NSRegularExpression(pattern: insertPattern, options: []) {
            let matches = insertRegex.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
            for match in matches.reversed() {
                guard match.numberOfRanges == 3,
                      let afterRange = Range(match.range(at: 1), in: response),
                      let contentRange = Range(match.range(at: 2), in: response),
                      let fullRange = Range(match.range(at: 0), in: response) else { continue }
                
                let after = String(response[afterRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rawText = String(response[fullRange])
                
                actions.insert(AIAction(type: .insert(after: after, content: content), rawText: rawText), at: 0)
                cleanText = cleanText.replacingOccurrences(of: rawText, with: "")
            }
        }
        
        if let terminalRegex = try? NSRegularExpression(pattern: terminalPattern, options: []) {
            let matches = terminalRegex.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
            for match in matches.reversed() {
                guard match.numberOfRanges == 3,
                      let commandRange = Range(match.range(at: 1), in: response),
                      let reasonRange = Range(match.range(at: 2), in: response),
                      let fullRange = Range(match.range(at: 0), in: response) else { continue }
                
                let command = String(response[commandRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let reason = String(response[reasonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rawText = String(response[fullRange])
                
                actions.insert(AIAction(type: .terminal(command: command, reason: reason), rawText: rawText), at: 0)
                cleanText = cleanText.replacingOccurrences(of: rawText, with: "")
            }
        }
        
        if let searchRegex = try? NSRegularExpression(pattern: searchPattern, options: []) {
            let matches = searchRegex.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
            for match in matches.reversed() {
                guard match.numberOfRanges == 3,
                      let patternRange = Range(match.range(at: 1), in: response),
                      let reasonRange = Range(match.range(at: 2), in: response),
                      let fullRange = Range(match.range(at: 0), in: response) else { continue }
                
                let pattern = String(response[patternRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let reason = String(response[reasonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rawText = String(response[fullRange])
                
                actions.insert(AIAction(type: .search(pattern: pattern, reason: reason), rawText: rawText), at: 0)
                cleanText = cleanText.replacingOccurrences(of: rawText, with: "")
            }
        }
        
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (cleanText, actions)
    }
}
