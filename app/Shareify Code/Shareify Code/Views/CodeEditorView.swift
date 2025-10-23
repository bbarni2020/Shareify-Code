//
//  CodeEditorView.swift
//  Shareify Code
//
//  Created by Balogh Barnabás on 2025. 10. 21.
//

import SwiftUI
import UIKit

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    let language: ProgrammingLanguage
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let storage = HighlightingTextStorage(language: language, theme: .xcodeDefault)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        let textView = UITextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.autocorrectionType = UITextAutocorrectionType.no
        textView.autocapitalizationType = UITextAutocapitalizationType.none
        textView.smartDashesType = UITextSmartDashesType.no
        textView.smartQuotesType = UITextSmartQuotesType.no
        textView.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        textView.keyboardType = UIKeyboardType.default
        textView.keyboardAppearance = UIKeyboardAppearance.dark
        textView.backgroundColor = UIColor(red: 0.059, green: 0.059, blue: 0.071, alpha: 1.0)
        textView.textColor = UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0)
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        
        if !text.isEmpty {
            storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if let storage = textView.textStorage as? HighlightingTextStorage {
            storage.updateLanguage(language)
        }
        
        if textView.text != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange
            
            if let storage = textView.textStorage as? HighlightingTextStorage {
                storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
            } else {
                textView.text = text
            }
            
            if selectedRange.location <= text.count {
                textView.selectedRange = selectedRange
            }
        }
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        var isUpdating = false
        
        init(_ parent: CodeEditorView) {
            self.parent = parent
            super.init()
        }
        
        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            
            isUpdating = true
            parent.text = textView.text
            isUpdating = false
        }
    }
}
