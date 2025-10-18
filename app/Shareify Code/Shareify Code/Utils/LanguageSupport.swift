//
//  LanguageSupport.swift
//  Shareify Code
//


import SwiftUI

struct LanguageInfo {
    let name: String
    let icon: String
    let color: Color
    let extensions: [String]
    
    var displayIcon: String {
        icon
    }
}

enum ProgrammingLanguage {
    case swift
    case python
    case javascript
    case typescript
    case react
    case reactTypescript
    case java
    case csharp
    case cpp
    case c
    case rust
    case go
    case ruby
    case php
    case html
    case css
    case json
    case xml
    case yaml
    case markdown
    case text
    case shell
    case sql
    case kotlin
    case dart
    case r
    case perl
    case scala
    case vue
    case svelte
    case unknown
    
    var info: LanguageInfo {
        switch self {
        case .swift:
            return LanguageInfo(name: "Swift", icon: "swift", color: .orange, extensions: ["swift"])
        case .python:
            return LanguageInfo(name: "Python", icon: "chevron.left.forwardslash.chevron.right", color: Color(red: 0.26, green: 0.45, blue: 0.82), extensions: ["py", "pyw", "pyc"])
        case .javascript:
            return LanguageInfo(name: "JavaScript", icon: "curlybraces", color: .yellow, extensions: ["js", "mjs", "cjs"])
        case .typescript:
            return LanguageInfo(name: "TypeScript", icon: "curlybraces.square", color: Color(red: 0.0, green: 0.48, blue: 0.80), extensions: ["ts"])
        case .react:
            return LanguageInfo(name: "React", icon: "atom", color: Color(red: 0.0, green: 0.82, blue: 0.95), extensions: ["jsx"])
        case .reactTypescript:
            return LanguageInfo(name: "React TS", icon: "atom", color: Color(red: 0.0, green: 0.48, blue: 0.80), extensions: ["tsx"])
        case .java:
            return LanguageInfo(name: "Java", icon: "cup.and.saucer", color: .red, extensions: ["java", "class", "jar"])
        case .csharp:
            return LanguageInfo(name: "C#", icon: "number", color: Color(red: 0.4, green: 0.2, blue: 0.6), extensions: ["cs", "csx"])
        case .cpp:
            return LanguageInfo(name: "C++", icon: "c.circle", color: Color(red: 0.0, green: 0.4, blue: 0.8), extensions: ["cpp", "cc", "cxx", "hpp", "h++", "hxx"])
        case .c:
            return LanguageInfo(name: "C", icon: "c.circle.fill", color: Color(red: 0.25, green: 0.35, blue: 0.55), extensions: ["c", "h"])
        case .rust:
            return LanguageInfo(name: "Rust", icon: "gearshape.2", color: Color(red: 0.87, green: 0.45, blue: 0.28), extensions: ["rs"])
        case .go:
            return LanguageInfo(name: "Go", icon: "flag.fill", color: Color(red: 0.0, green: 0.68, blue: 0.84), extensions: ["go"])
        case .ruby:
            return LanguageInfo(name: "Ruby", icon: "diamond", color: .red, extensions: ["rb", "erb", "rake"])
        case .php:
            return LanguageInfo(name: "PHP", icon: "server.rack", color: Color(red: 0.31, green: 0.38, blue: 0.54), extensions: ["php", "phtml"])
        case .html:
            return LanguageInfo(name: "HTML", icon: "chevron.left.slash.chevron.right", color: Color(red: 0.89, green: 0.33, blue: 0.18), extensions: ["html", "htm", "xhtml"])
        case .css:
            return LanguageInfo(name: "CSS", icon: "paintbrush.fill", color: Color(red: 0.0, green: 0.45, blue: 0.85), extensions: ["css", "scss", "sass", "less"])
        case .json:
            return LanguageInfo(name: "JSON", icon: "curlybraces", color: .green, extensions: ["json", "jsonc"])
        case .xml:
            return LanguageInfo(name: "XML", icon: "chevron.left.2", color: Color(red: 0.8, green: 0.5, blue: 0.0), extensions: ["xml", "plist", "xib", "storyboard"])
        case .yaml:
            return LanguageInfo(name: "YAML", icon: "list.bullet.indent", color: Color(red: 0.8, green: 0.2, blue: 0.3), extensions: ["yaml", "yml"])
        case .markdown:
            return LanguageInfo(name: "Markdown", icon: "doc.plaintext", color: .gray, extensions: ["md", "markdown"])
        case .text:
            return LanguageInfo(name: "Text", icon: "doc.text", color: .gray, extensions: ["txt", "log", "text"])
        case .shell:
            return LanguageInfo(name: "Shell", icon: "terminal", color: .green, extensions: ["sh", "bash", "zsh", "fish"])
        case .sql:
            return LanguageInfo(name: "SQL", icon: "cylinder", color: Color(red: 0.2, green: 0.6, blue: 0.8), extensions: ["sql"])
        case .kotlin:
            return LanguageInfo(name: "Kotlin", icon: "k.square", color: Color(red: 0.49, green: 0.38, blue: 0.93), extensions: ["kt", "kts"])
        case .dart:
            return LanguageInfo(name: "Dart", icon: "d.circle", color: Color(red: 0.0, green: 0.65, blue: 0.84), extensions: ["dart"])
        case .r:
            return LanguageInfo(name: "R", icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.13, green: 0.40, blue: 0.65), extensions: ["r", "R"])
        case .perl:
            return LanguageInfo(name: "Perl", icon: "p.circle", color: Color(red: 0.0, green: 0.30, blue: 0.60), extensions: ["pl", "pm"])
        case .scala:
            return LanguageInfo(name: "Scala", icon: "s.circle", color: .red, extensions: ["scala", "sc"])
        case .vue:
            return LanguageInfo(name: "Vue", icon: "v.circle", color: Color(red: 0.25, green: 0.71, blue: 0.53), extensions: ["vue"])
        case .svelte:
            return LanguageInfo(name: "Svelte", icon: "bolt.fill", color: Color(red: 1.0, green: 0.24, blue: 0.13), extensions: ["svelte"])
        case .unknown:
            return LanguageInfo(name: "Unknown", icon: "doc", color: Color(red: 0.118, green: 0.161, blue: 0.231), extensions: [])
        }
    }
    
    static func detect(from url: URL) -> ProgrammingLanguage {
        let ext = url.pathExtension.lowercased()
        
        let allLanguages: [ProgrammingLanguage] = [
            .swift, .python, .javascript, .typescript, .react, .reactTypescript,
            .java, .csharp, .cpp, .c, .rust, .go, .ruby, .php, .html, .css, 
            .json, .xml, .yaml, .markdown, .text, .shell, .sql, .kotlin,
            .dart, .r, .perl, .scala, .vue, .svelte
        ]
        
        for language in allLanguages {
            if language.info.extensions.contains(ext) {
                return language
            }
        }
        
        return .unknown
    }
}

extension URL {
    var detectedLanguage: ProgrammingLanguage {
        ProgrammingLanguage.detect(from: self)
    }
    
    var languageInfo: LanguageInfo {
        detectedLanguage.info
    }
}
