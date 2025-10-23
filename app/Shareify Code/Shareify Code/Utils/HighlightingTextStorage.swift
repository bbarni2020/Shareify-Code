import UIKit

final class HighlightingTextStorage: NSTextStorage {
    private let storage = NSMutableAttributedString()
    private let highlighter: SyntaxHighlighter
    private var language: ProgrammingLanguage
    private var highlightQueue = DispatchQueue(label: "com.shareify.highlighting", qos: .userInitiated)
    private var pendingHighlight: DispatchWorkItem?
    
    init(language: ProgrammingLanguage, theme: SyntaxColorTheme = .xcodeDefault) {
        self.language = language
        self.highlighter = SyntaxHighlighter(theme: theme)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func updateLanguage(_ newLanguage: ProgrammingLanguage) {
        guard language != newLanguage else { return }
        language = newLanguage
        performFullHighlight()
    }
    
    override var string: String {
        storage.string
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        storage.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        storage.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func processEditing() {
        super.processEditing()
        
        if editedMask.contains(.editedCharacters) {
            let changedRange = editedRange
            scheduleHighlight(in: expandedRange(for: changedRange))
        }
    }
    
    private func scheduleHighlight(in range: NSRange) {
        pendingHighlight?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.highlighter.highlight(textStorage: self, language: self.language)
            }
        }
        
        pendingHighlight = workItem
        highlightQueue.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }
    
    private func performFullHighlight() {
        scheduleHighlight(in: NSRange(location: 0, length: storage.length))
    }
    
    private func expandedRange(for range: NSRange) -> NSRange {
        let text = storage.string as NSString
        var expandedRange = range
        
        if expandedRange.location > 0 {
            let lineStart = text.lineRange(for: NSRange(location: expandedRange.location, length: 0)).location
            expandedRange.location = lineStart
            expandedRange.length += (range.location - lineStart)
        }
        
        let lineEnd = text.lineRange(for: NSRange(location: NSMaxRange(range), length: 0))
        let maxRange = NSMaxRange(lineEnd)
        if maxRange > NSMaxRange(expandedRange) {
            expandedRange.length += (maxRange - NSMaxRange(expandedRange))
        }
        
        return expandedRange
    }
}
