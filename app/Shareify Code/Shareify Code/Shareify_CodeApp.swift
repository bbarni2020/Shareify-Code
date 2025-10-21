//
//  Shareify_CodeApp.swift
//  Shareify Code
//
//  Created by Balogh Barnabás on 2025. 10. 18..
//

import SwiftUI

@main
struct Shareify_CodeApp: App {
    @StateObject private var vm = WorkspaceViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .tint(.appAccent)
                .preferredColorScheme(.dark)
                .background(Color.appBackground)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") { vm.openFolder() }
                    .keyboardShortcut("o", modifiers: [.command])
            }

            CommandGroup(after: .saveItem) {
                Button("Save") { vm.saveActive() }
                    .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}
