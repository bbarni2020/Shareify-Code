//
//  CodeEditorView.swift
//  Shareify Code
//
//  Created by Balogh Barnabás on 2025. 10. 21.
//

import SwiftUI
import UIKit
import Highlightr

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    let language: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.keyboardType = .default
        textView.keyboardAppearance = .dark
        textView.backgroundColor = .clear


        if let highlightr = context.coordinator.highlightr {
            highlightr.setTheme(to: "atom-one-dark")
            highlightr.theme.setCodeFont(UIFont.monospacedSystemFont(ofSize: 14, weight: .regular))

            let storage = CodeAttributedString(highlightr: highlightr)
            storage.language = language
            
            let layoutManager = textView.layoutManager
            layoutManager.textStorage?.removeLayoutManager(layoutManager)
            storage.addLayoutManager(layoutManager)
            
            textView.text = text
        } else {
            textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            textView.text = text
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if let storage = textView.textStorage as? CodeAttributedString {
            if storage.language != language {
                storage.language = language
            }
        }
        
        if textView.text != text && !context.coordinator.isUpdating {
            let selectedRange = textView.selectedRange
            
            textView.text = text
            
            if selectedRange.location <= text.count {
                textView.selectedRange = selectedRange
            }
        }
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        var isUpdating = false
        let highlightr = Highlightr()
        
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
