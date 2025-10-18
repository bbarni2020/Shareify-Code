import SwiftUI

#if os(macOS)
import AppKit

struct SyntaxHighlightingTextEditor: NSViewRepresentable {
    @Binding var text: String
    let language: ProgrammingLanguage

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isRichText = false
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.string = text
        context.coordinator.applyHighlighting(in: textView)

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.documentView = textView
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            context.coordinator.isProgrammaticChange = true
            textView.string = text
            context.coordinator.applyHighlighting(in: textView)
            context.coordinator.isProgrammaticChange = false
        } else {
            context.coordinator.applyHighlighting(in: textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightingTextEditor
        var isProgrammaticChange = false
        let highlighter = CodeSyntaxHighlighter()

        init(_ parent: SyntaxHighlightingTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if !isProgrammaticChange {
                parent.text = textView.string
                applyHighlighting(in: textView)
            }
        }

        func applyHighlighting(in textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: storage.length)
            let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .regular)
            storage.beginEditing()
            storage.setAttributes([
                .font: font,
                .foregroundColor: NSColor.labelColor
            ], range: fullRange)
            highlighter.highlight(storage: storage, language: parent.language)
            storage.endEditing()
        }
    }
}

final class CodeSyntaxHighlighter {
    func highlight(storage: NSTextStorage, language: ProgrammingLanguage) {
        let text = storage.string
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        let protect = protectedRanges(in: text)
        apply(pattern: commentBlockPattern, color: .systemGray, to: storage, in: text)
        apply(pattern: commentLinePattern, color: .systemGray, to: storage, in: text)
        apply(pattern: stringPattern, color: .systemGreen, to: storage, in: text)
        apply(pattern: multilineStringPattern, color: .systemGreen, to: storage, in: text)
        apply(pattern: numberPattern, color: .systemOrange, to: storage, in: text, skipping: protect)
        apply(pattern: attributePattern, color: .systemPurple, to: storage, in: text, skipping: protect)
        apply(pattern: directivePattern, color: .systemPink, to: storage, in: text, skipping: protect)
        let kw = keywords(for: language)
        if !kw.isEmpty {
            let regex = try? NSRegularExpression(pattern: "\\b(?:" + kw.map(escape).joined(separator: "|") + ")\\b")
            enumerate(regex: regex, in: text) { r in
                if !overlaps(r, protect) { storage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: r) }
            }
        }
        let typeRegex = try? NSRegularExpression(pattern: "\\b[A-Z][A-Za-z0-9_]*\\b")
        enumerate(regex: typeRegex, in: text) { r in
            if !overlaps(r, protect) { storage.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: r) }
        }
        storage.fixAttributes(in: full)
    }

    func keywords(for language: ProgrammingLanguage) -> [String] {
        switch language {
        case .swift:
            return ["associatedtype","class","deinit","enum","extension","fileprivate","func","import","init","inout","internal","let","open","operator","private","protocol","public","rethrows","static","struct","subscript","typealias","var","break","case","continue","default","defer","do","else","fallthrough","for","guard","if","in","repeat","return","switch","where","while","as","Any","catch","false","is","nil","super","self","Self","throw","throws","true","try","await","async","some"]
        case .python:
            return ["and","as","assert","break","class","continue","def","del","elif","else","except","False","finally","for","from","global","if","import","in","is","lambda","None","nonlocal","not","or","pass","raise","return","True","try","while","with","yield"]
        case .javascript:
            return ["break","case","catch","class","const","continue","debugger","default","delete","do","else","export","extends","finally","for","function","if","import","in","instanceof","let","new","return","super","switch","this","throw","try","typeof","var","void","while","with","yield","await","async"]
        case .typescript:
            return ["abstract","any","as","asserts","bigint","boolean","break","case","catch","class","const","constructor","continue","declare","default","delete","do","else","enum","export","extends","false","finally","for","from","function","get","if","implements","import","in","infer","instanceof","interface","is","keyof","let","module","namespace","never","new","null","number","object","package","private","protected","public","readonly","require","global","return","set","static","string","super","switch","symbol","this","throw","true","try","type","typeof","undefined","unique","unknown","var","void","while","with","yield","await","async"]
        case .java:
            return ["abstract","assert","boolean","break","byte","case","catch","char","class","const","continue","default","do","double","else","enum","extends","final","finally","float","for","goto","if","implements","import","instanceof","int","interface","long","native","new","package","private","protected","public","return","short","static","strictfp","super","switch","synchronized","this","throw","throws","transient","try","void","volatile","while"]
        case .c:
            return ["auto","break","case","char","const","continue","default","do","double","else","enum","extern","float","for","goto","if","inline","int","long","register","restrict","return","short","signed","sizeof","static","struct","switch","typedef","union","unsigned","void","volatile","while","_Bool","_Complex","_Imaginary"]
        case .cpp:
            return ["alignas","alignof","and","and_eq","asm","auto","bitand","bitor","bool","break","case","catch","char","char16_t","char32_t","class","compl","const","constexpr","const_cast","continue","decltype","default","delete","do","double","dynamic_cast","else","enum","explicit","export","extern","false","float","for","friend","goto","if","inline","int","long","mutable","namespace","new","noexcept","not","not_eq","nullptr","operator","or","or_eq","private","protected","public","register","reinterpret_cast","return","short","signed","sizeof","static","static_cast","struct","switch","template","this","thread_local","throw","true","try","typedef","typeid","typename","union","unsigned","using","virtual","void","volatile","wchar_t","while","xor","xor_eq"]
        case .csharp:
            return ["abstract","as","base","bool","break","byte","case","catch","char","checked","class","const","continue","decimal","default","delegate","do","double","else","enum","event","explicit","extern","false","finally","fixed","float","for","foreach","goto","if","implicit","in","int","interface","internal","is","lock","long","namespace","new","null","object","operator","out","override","params","private","protected","public","readonly","ref","return","sbyte","sealed","short","sizeof","stackalloc","static","string","struct","switch","this","throw","true","try","typeof","uint","ulong","unchecked","unsafe","ushort","using","virtual","void","volatile","while","await","async","var","dynamic"]
        case .rust:
            return ["as","break","const","continue","crate","else","enum","extern","false","fn","for","if","impl","in","let","loop","match","mod","move","mut","pub","ref","return","self","Self","static","struct","super","trait","true","type","unsafe","use","where","while","async","await","dyn"]
        case .go:
            return ["break","case","chan","const","continue","default","defer","else","fallthrough","for","func","go","goto","if","import","interface","map","package","range","return","select","struct","switch","type","var"]
        case .ruby:
            return ["BEGIN","END","alias","and","begin","break","case","class","def","defined?","do","else","elsif","end","ensure","false","for","if","in","module","next","nil","not","or","redo","rescue","retry","return","self","super","then","true","undef","unless","until","when","while","yield"]
        case .php:
            return ["abstract","and","array","as","break","callable","case","catch","class","clone","const","continue","declare","default","die","do","echo","else","elseif","empty","enddeclare","endfor","endforeach","endif","endswitch","endwhile","eval","exit","extends","final","finally","for","foreach","function","global","goto","if","implements","include","include_once","instanceof","insteadof","interface","isset","list","namespace","new","or","print","private","protected","public","require","require_once","return","static","switch","throw","trait","try","unset","use","var","while","xor"]
        case .kotlin:
            return ["as","break","class","continue","do","else","false","for","fun","if","in","interface","is","null","object","package","return","super","this","throw","true","try","typealias","val","var","when","while","by","catch","constructor","delegate","dynamic","field","file","finally","get","import","init","param","property","receiver","set","setparam","value","where"]
        case .typescript:
            return ["abstract","any","as","asserts","bigint","boolean","break","case","catch","class","const","constructor","continue","declare","default","delete","do","else","enum","export","extends","false","finally","for","from","function","get","if","implements","import","in","infer","instanceof","interface","is","keyof","let","module","namespace","never","new","null","number","object","package","private","protected","public","readonly","require","global","return","set","static","string","super","switch","symbol","this","throw","true","try","type","typeof","undefined","unique","unknown","var","void","while","with","yield","await","async"]
        default:
            return []
        }
    }

    func apply(pattern: String, color: NSColor, to storage: NSTextStorage, in text: String, skipping: [NSRange] = []) {
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
        enumerate(regex: regex, in: text) { r in
            if !overlaps(r, skipping) { storage.addAttribute(.foregroundColor, value: color, range: r) }
        }
    }

    func enumerate(regex: NSRegularExpression?, in text: String, _ block: (NSRange) -> Void) {
        guard let regex else { return }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        regex.enumerateMatches(in: text, options: [], range: full) { match, _, _ in
            if let r = match?.range { block(r) }
        }
    }

    func overlaps(_ r: NSRange, _ ranges: [NSRange]) -> Bool {
        for a in ranges { if NSIntersectionRange(r, a).length > 0 { return true } }
        return false
    }

    func protectedRanges(in text: String) -> [NSRange] {
        var res: [NSRange] = []
        let patterns = [multilineStringPattern, stringPattern, commentBlockPattern, commentLinePattern]
        for p in patterns {
            let rx = try? NSRegularExpression(pattern: p, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
            enumerate(regex: rx, in: text) { r in res.append(r) }
        }
        return res
    }

    func escape(_ s: String) -> String {
        NSRegularExpression.escapedPattern(for: s)
    }
}

let stringPattern = "\"(?:\\\\.|[^\"\\\\])*\""
let multilineStringPattern = "\"\"\"[\\n\\r\\s\\S]*?\"\"\""
let commentLinePattern = "(?m)//.*$|(?m)#.*$"
let commentBlockPattern = "/\\*[\\n\\r\\s\\S]*?\\*/"
let numberPattern = "\\b(?:0x[0-9A-Fa-f_]+|0b[01_]+|0o[0-7_]+|[0-9][0-9_]*(?:\\.[0-9_]+)?)\\b"
let attributePattern = "@[_A-Za-z][_A-Za-z0-9]*"
let directivePattern = "(?m)^#[_A-Za-z][_A-Za-z0-9]*"

#else

struct SyntaxHighlightingTextEditor: View {
    @Binding var text: String
    let language: ProgrammingLanguage
    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
    }
}

#endif
