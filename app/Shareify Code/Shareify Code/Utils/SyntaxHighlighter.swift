import UIKit

final class SyntaxHighlighter {
    private let colorTheme: SyntaxColorTheme
    
    init(theme: SyntaxColorTheme = .xcodeDefault) {
        self.colorTheme = theme
    }
    
    func highlight(textStorage: NSTextStorage, language: ProgrammingLanguage) {
        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        
        textStorage.beginEditing()
        
        textStorage.setAttributes([
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: colorTheme.plainText
        ], range: fullRange)
        
        let protectedRanges = highlightStringsAndComments(in: textStorage, text: text, language: language)
        
        highlightNumbers(in: textStorage, text: text, excluding: protectedRanges)
        highlightAttributes(in: textStorage, text: text, excluding: protectedRanges)
        highlightDirectives(in: textStorage, text: text, excluding: protectedRanges)
        highlightKeywords(in: textStorage, text: text, language: language, excluding: protectedRanges)
        highlightTypes(in: textStorage, text: text, excluding: protectedRanges)
        highlightFunctionCalls(in: textStorage, text: text, excluding: protectedRanges)
        
        textStorage.endEditing()
    }
    
    private func highlightStringsAndComments(in textStorage: NSTextStorage, text: String, language: ProgrammingLanguage) -> [NSRange] {
        var protectedRanges: [NSRange] = []
        
        applyPattern(multilineStringPattern, color: colorTheme.string, to: textStorage, in: text, protected: &protectedRanges)
        applyPattern(stringPattern, color: colorTheme.string, to: textStorage, in: text, protected: &protectedRanges)
        applyPattern(commentBlockPattern, color: colorTheme.comment, to: textStorage, in: text, protected: &protectedRanges)
        
        let commentPattern = commentLinePattern(for: language)
        applyPattern(commentPattern, color: colorTheme.comment, to: textStorage, in: text, protected: &protectedRanges)
        
        return protectedRanges
    }
    
    private func highlightNumbers(in textStorage: NSTextStorage, text: String, excluding: [NSRange]) {
        applyPattern(numberPattern, color: colorTheme.number, to: textStorage, in: text, skipping: excluding)
    }
    
    private func highlightAttributes(in textStorage: NSTextStorage, text: String, excluding: [NSRange]) {
        applyPattern(attributePattern, color: colorTheme.attribute, to: textStorage, in: text, skipping: excluding)
    }
    
    private func highlightDirectives(in textStorage: NSTextStorage, text: String, excluding: [NSRange]) {
        applyPattern(directivePattern, color: colorTheme.directive, to: textStorage, in: text, skipping: excluding)
    }
    
    private func highlightKeywords(in textStorage: NSTextStorage, text: String, language: ProgrammingLanguage, excluding: [NSRange]) {
        let keywords = keywordSet(for: language)
        guard !keywords.isEmpty else { return }
        
        let pattern = "\\b(?:" + keywords.map(NSRegularExpression.escapedPattern).joined(separator: "|") + ")\\b"
        applyPattern(pattern, color: colorTheme.keyword, to: textStorage, in: text, skipping: excluding)
    }
    
    private func highlightTypes(in textStorage: NSTextStorage, text: String, excluding: [NSRange]) {
        applyPattern(typePattern, color: colorTheme.type, to: textStorage, in: text, skipping: excluding)
    }
    
    private func highlightFunctionCalls(in textStorage: NSTextStorage, text: String, excluding: [NSRange]) {
        applyPattern(functionCallPattern, color: colorTheme.function, to: textStorage, in: text, skipping: excluding)
    }
    
    private func applyPattern(_ pattern: String, color: UIColor, to textStorage: NSTextStorage, in text: String, skipping: [NSRange] = [], protected: inout [NSRange]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .anchorsMatchLines]) else { return }
        
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let matchRange = match?.range else { return }
            if !overlaps(matchRange, skipping) {
                textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                protected.append(matchRange)
            }
        }
    }
    
    private func applyPattern(_ pattern: String, color: UIColor, to textStorage: NSTextStorage, in text: String, skipping: [NSRange] = []) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .anchorsMatchLines]) else { return }
        
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let matchRange = match?.range else { return }
            if !overlaps(matchRange, skipping) {
                textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
            }
        }
    }
    
    private func overlaps(_ range: NSRange, _ ranges: [NSRange]) -> Bool {
        for r in ranges {
            if NSIntersectionRange(range, r).length > 0 {
                return true
            }
        }
        return false
    }
    
    private func keywordSet(for language: ProgrammingLanguage) -> [String] {
        switch language {
        case .swift:
            return ["associatedtype","class","deinit","enum","extension","fileprivate","func","import","init","inout","internal","let","open","operator","private","protocol","public","rethrows","static","struct","subscript","typealias","var","break","case","continue","default","defer","do","else","fallthrough","for","guard","if","in","repeat","return","switch","where","while","as","Any","catch","false","is","nil","super","self","Self","throw","throws","true","try","await","async","some","actor","isolated","nonisolated"]
        case .python:
            return ["and","as","assert","break","class","continue","def","del","elif","else","except","False","finally","for","from","global","if","import","in","is","lambda","None","nonlocal","not","or","pass","raise","return","True","try","while","with","yield","async","await"]
        case .javascript, .typescript:
            return ["break","case","catch","class","const","continue","debugger","default","delete","do","else","export","extends","finally","for","function","if","import","in","instanceof","let","new","return","super","switch","this","throw","try","typeof","var","void","while","with","yield","await","async","of"]
        case .java:
            return ["abstract","assert","boolean","break","byte","case","catch","char","class","const","continue","default","do","double","else","enum","extends","final","finally","float","for","goto","if","implements","import","instanceof","int","interface","long","native","new","package","private","protected","public","return","short","static","strictfp","super","switch","synchronized","this","throw","throws","transient","try","void","volatile","while"]
        case .c, .cpp:
            return ["auto","break","case","char","const","continue","default","do","double","else","enum","extern","float","for","goto","if","inline","int","long","register","restrict","return","short","signed","sizeof","static","struct","switch","typedef","union","unsigned","void","volatile","while","class","namespace","using","template","typename","virtual","public","private","protected"]
        case .csharp:
            return ["abstract","as","base","bool","break","byte","case","catch","char","checked","class","const","continue","decimal","default","delegate","do","double","else","enum","event","explicit","extern","false","finally","fixed","float","for","foreach","goto","if","implicit","in","int","interface","internal","is","lock","long","namespace","new","null","object","operator","out","override","params","private","protected","public","readonly","ref","return","sbyte","sealed","short","sizeof","stackalloc","static","string","struct","switch","this","throw","true","try","typeof","uint","ulong","unchecked","unsafe","ushort","using","virtual","void","volatile","while","await","async","var","dynamic"]
        case .rust:
            return ["as","break","const","continue","crate","else","enum","extern","false","fn","for","if","impl","in","let","loop","match","mod","move","mut","pub","ref","return","self","Self","static","struct","super","trait","true","type","unsafe","use","where","while","async","await","dyn"]
        case .go:
            return ["break","case","chan","const","continue","default","defer","else","fallthrough","for","func","go","goto","if","import","interface","map","package","range","return","select","struct","switch","type","var"]
        case .kotlin:
            return ["as","break","class","continue","do","else","false","for","fun","if","in","interface","is","null","object","package","return","super","this","throw","true","try","typealias","val","var","when","while","by","catch","constructor","delegate","dynamic","field","file","finally","get","import","init","param","property","receiver","set","setparam","value","where"]
        default:
            return []
        }
    }
    
    private func commentLinePattern(for language: ProgrammingLanguage) -> String {
        switch language {
        case .python, .ruby, .shell, .yaml, .perl, .r:
            return "(?m)#.*$"
        case .c, .cpp, .java, .javascript, .typescript, .swift, .rust, .go, .kotlin, .csharp, .scala, .dart, .php:
            return "(?m)(?<!:)//.*$"
        default:
            return "(?m)(?<!:)//.*$|(?m)#.*$"
        }
    }
}

private let stringPattern = "\"(?:\\\\.|[^\"\\\\])*\""
private let multilineStringPattern = "\"\"\"[\\s\\S]*?\"\"\""
private let commentBlockPattern = "/\\*[\\s\\S]*?\\*/"
private let numberPattern = "\\b(?:0x[0-9A-Fa-f_]+|0b[01_]+|0o[0-7_]+|[0-9][0-9_]*(?:\\.[0-9_]+)?(?:[eE][+-]?[0-9]+)?)\\b"
private let attributePattern = "@[_A-Za-z][_A-Za-z0-9]*"
private let directivePattern = "(?m)^\\s*#[_A-Za-z][_A-Za-z0-9]*"
private let typePattern = "\\b[A-Z][A-Za-z0-9_]*\\b"
private let functionCallPattern = "\\b[a-z_][a-zA-Z0-9_]*(?=\\s*\\()"
