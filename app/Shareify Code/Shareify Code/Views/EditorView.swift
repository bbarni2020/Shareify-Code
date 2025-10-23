import SwiftUI
import AVKit
import PDFKit

struct EditorView: View {
    @ObservedObject var vm: WorkspaceViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(vm: vm)
            
            if let active = vm.openFiles.first(where: { $0.id == vm.activeFileID }) {
                VStack(spacing: 0) {
                    HStack(spacing: Theme.spacingM) {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: active.url.languageInfo.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(active.url.languageInfo.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(active.url.languageInfo.color)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingXS)
                        .background(
                            Capsule()
                                .fill(active.url.languageInfo.color.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(active.url.languageInfo.color.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text(active.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        
                        if active.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.top, Theme.spacingM)
                    .padding(.bottom, Theme.spacingM)
                    
                    if active.isLoading {
                        VStack(spacing: Theme.spacingL) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Loading file from server...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.bottom, Theme.spacingL)
                    } else if active.url.detectedLanguage != .unknown {
                        SyntaxHighlightingTextEditor(
                            text: Binding<String>(
                                get: { active.content },
                                set: { vm.updateActiveContent($0) }
                            ),
                            language: active.url.detectedLanguage
                        )
                        .padding(Theme.spacingL)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.bottom, Theme.spacingL)
                    } else {
                        MediaContentView(file: active)
                            .padding(.horizontal, Theme.spacingL)
                            .padding(.bottom, Theme.spacingL)
                    }
                    
                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                NoFileOpenView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            StatusBarView(vm: vm)
        }
        .background(Color.appBackground)
        .sheet(isPresented: $vm.showNotesView) {
            NotesView(vm: vm)
        }
    }
}

private struct TabBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @State private var hoverTab: String?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingXS) {
                    ForEach(vm.openFiles) { file in
                        let isActive = file.id == vm.activeFileID
                        let isHovering = hoverTab == file.id
                        
                        HStack(spacing: Theme.spacingS) {
                            HStack(spacing: Theme.spacingS) {
                                Image(systemName: file.url.languageInfo.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(file.url.languageInfo.color)
                                
                                Text(file.title)
                                    .font(.system(size: Theme.uiFontSize, design: .rounded))
                                    .foregroundStyle(
                                        isActive ? Color.appTextPrimary : Color.appTextSecondary
                                    )
                                
                                if file.isDirty {
                                    Circle()
                                        .fill(Color.appAccent)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .fill(
                                        isActive 
                                            ? Color.appSurfaceElevated 
                                            : (isHovering ? Color.appSurfaceHover : Color.clear)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                    .stroke(
                                        isActive ? Color.appBorder : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { vm.activeFileID = file.id }
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: Theme.animationFast)) {
                                    hoverTab = hovering ? file.id : nil
                                }
                            }
                            
                            Button {
                                vm.closeFile(file.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.appTextTertiary)
                                    .frame(width: 16, height: 16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            
            Divider()
                .frame(height: 24)
            
            if let activeFile = vm.openFiles.first(where: { $0.id == vm.activeFileID }), activeFile.isServerFile {
                Button(action: { vm.shareServerFile(activeFile) }) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .medium))
                        Text("Share")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 24)
            }
            
            Button(action: { vm.showNotesView = true }) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 12, weight: .medium))
                    Text("Notes")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 24)
            
            Button(action: vm.saveActive) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s")
        }
        .frame(height: 44)
        .background(
            Color.appSurface
                .overlay(
                    Rectangle()
                        .fill(Color.appBorderSubtle)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        )
    }
}

private struct StatusBarView: View {
    @ObservedObject var vm: WorkspaceViewModel
    
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            if let id = vm.activeFileID, let file = vm.openFiles.first(where: { $0.id == id }) {
                Text(file.url.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextTertiary)
                
                Circle()
                    .fill(Color.appBorder)
                    .frame(width: 3, height: 3)
                
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: file.url.languageInfo.icon)
                        .font(.system(size: 10))
                    Text(file.url.languageInfo.name)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(file.url.languageInfo.color)
                
                if !file.url.pathExtension.isEmpty {
                    Circle()
                        .fill(Color.appBorder)
                        .frame(width: 3, height: 3)
                    
                    Text(".\(file.url.pathExtension)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextTertiary)
                }
            } else {
                HStack(spacing: Theme.spacingXS) {
                    Circle()
                        .fill(Color.successColor)
                        .frame(width: 6, height: 6)
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            
            Spacer()
            
            Button(action: vm.saveActive) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 10))
                    Text("Save")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.appTextSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s")
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingS)
        .background(
            Color.appSurface
                .overlay(
                    Rectangle()
                        .fill(Color.appBorderSubtle)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
        )
    }
}

private struct NoFileOpenView: View {
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.15), lineWidth: 2)
                .frame(width: 160, height: 160)
                .blur(radius: 12)
                .opacity(pulse ? 0.3 : 0.5)
                .scaleEffect(pulse ? 1.1 : 0.9)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: pulse
                )
            
            VStack(spacing: Theme.spacingL) {
                ZStack {
                    Circle()
                        .fill(Color.appSurfaceElevated)
                        .frame(width: 96, height: 96)
                        .shadow(color: Theme.subtleShadow, radius: 20, x: 0, y: 8)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.appTextTertiary)
                }
                
                VStack(spacing: Theme.spacingXS) {
                    Text("No file open")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    
                    Text("Select a file from the explorer to start editing")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .task { pulse = true }
    }
}

private struct MediaContentView: View {
    let file: WorkspaceViewModel.OpenFile
    
    var body: some View {
        VStack(spacing: 0) {
            switch file.fileType {
            case .image:
                ImageViewer(file: file)
            case .video:
                VideoViewer(file: file)
            case .audio:
                AudioViewer(file: file)
            case .pdf:
                PDFViewer(file: file)
            case .text:
                UnsupportedFileView(file: file)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCodeBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

private struct ImageViewer: View {
    let file: WorkspaceViewModel.OpenFile
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: Theme.spacingM) {
                    if let data = file.binaryData, let nsImage = createImage(from: data) {
                        #if os(macOS)
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #else
                        Image(uiImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    } else {
                        VStack(spacing: Theme.spacingM) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.appTextTertiary)
                            Text("Unable to load image")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(Theme.spacingL)
            }
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: Theme.spacingS) {
                    Button(action: { scale = max(0.1, scale - 0.25) }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(Int(scale * 100))%")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(minWidth: 45)
                    
                    Button(action: { scale = min(5.0, scale + 0.25) }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { scale = 1.0 }) {
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                        .fill(Color.appSurfaceElevated)
                        .shadow(color: Theme.subtleShadow, radius: 12, x: 0, y: 4)
                )
                .padding(Theme.spacingL)
            }
        }
    }
    
    private func createImage(from data: Data) -> NativeImage? {
        #if os(macOS)
        return NSImage(data: data)
        #else
        return UIImage(data: data)
        #endif
    }
}

private struct VideoViewer: View {
    let file: WorkspaceViewModel.OpenFile
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(spacing: Theme.spacingM) {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                VStack(spacing: Theme.spacingM) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appTextTertiary)
                    Text("Unable to load video")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(Theme.spacingL)
        .onAppear {
            player = AVPlayer(url: file.url)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

private struct AudioViewer: View {
    let file: WorkspaceViewModel.OpenFile
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: isPlaying ? "waveform" : "music.note")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.appAccent)
                    .symbolEffect(.pulse, options: .repeating, isActive: isPlaying)
            }
            
            VStack(spacing: Theme.spacingS) {
                Text(file.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Audio File")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
            }
            
            HStack(spacing: Theme.spacingL) {
                Button(action: {
                    if isPlaying {
                        player?.pause()
                    } else {
                        player?.play()
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(Theme.spacingXL)
        .onAppear {
            player = AVPlayer(url: file.url)
        }
        .onDisappear {
            player?.pause()
            player = nil
            isPlaying = false
        }
    }
}

private struct PDFViewer: View {
    let file: WorkspaceViewModel.OpenFile
    
    var body: some View {
        #if os(macOS)
        PDFKitView(url: file.url)
            .padding(Theme.spacingL)
        #else
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextTertiary)
            Text("PDF viewing not available on iOS")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(Theme.spacingL)
        #endif
    }
}

#if os(macOS)
private struct PDFKitView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {}
}
#endif

private struct UnsupportedFileView: View {
    let file: WorkspaceViewModel.OpenFile
    
    var body: some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.warningColor)
                
                Text("This file type isn't supported for editing")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .fill(Color.warningColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                    .stroke(Color.warningColor.opacity(0.3), lineWidth: 1)
            )
            
            ScrollView {
                Text(file.content)
                    .font(.system(size: Theme.codeFontSize, design: .monospaced))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(Theme.spacingL)
        }
        .padding(Theme.spacingL)
    }
}

#if os(macOS)
typealias NativeImage = NSImage
#else
typealias NativeImage = UIImage
#endif

struct NotesView: View {
    @ObservedObject var vm: WorkspaceViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        #if os(iOS)
        if vm.notes.isEmpty {
            let newNote = WorkspaceViewModel.Note(title: "Note")
            NoteEditorView(note: newNote, vm: vm, isNew: true)
                .onAppear {
                    vm.notes.append(newNote)
                }
        } else {
            NoteEditorView(note: vm.notes[0], vm: vm, isNew: false)
        }
        #else
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "hand.draw")
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextTertiary)
            
            VStack(spacing: Theme.spacingS) {
                Text("Drawing not supported on macOS")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Use an iPad or iPhone to draw notes with Apple Pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Close") {
                dismiss()
            }
            .padding(.top, Theme.spacingL)
        }
        .padding(Theme.spacingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

#if os(iOS)
import PencilKit

struct NoteEditorView: View {
    let note: WorkspaceViewModel.Note
    @ObservedObject var vm: WorkspaceViewModel
    let isNew: Bool
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    saveDrawing()
                    dismiss()
                }) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: "chevron.left")
                        Text("Close")
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(note.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Spacer()
                
                Button(action: clearDrawing) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.spacingL)
            
            Divider()
            
            PencilKitCanvasView(canvasView: $canvasView, toolPicker: $toolPicker, drawingData: note.drawingData)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appCodeBackground)
        }
        .background(Color.appSurface)
        .onAppear {
            loadDrawing()
        }
        .onDisappear {
            saveDrawing()
        }
    }
    
    private func loadDrawing() {
        if !note.drawingData.isEmpty {
            if let drawing = try? PKDrawing(data: note.drawingData) {
                canvasView.drawing = drawing
            }
        }
    }
    
    private func saveDrawing() {
        let drawingData = canvasView.drawing.dataRepresentation()
        vm.updateNote(note, drawingData: drawingData)
    }
    
    private func clearDrawing() {
        canvasView.drawing = PKDrawing()
    }
}

struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    let drawingData: Data
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = UIColor(Color.appCodeBackground)
        canvasView.isOpaque = true
        canvasView.drawingPolicy = .anyInput
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            canvasView.drawing = drawing
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

#else

struct NoteEditorView: View {
    let note: WorkspaceViewModel.Note
    @ObservedObject var vm: WorkspaceViewModel
    let isNew: Bool
    
    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "hand.draw")
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextTertiary)
            
            VStack(spacing: Theme.spacingS) {
                Text("Drawing not supported on macOS")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Use an iPad or iPhone to draw notes with Apple Pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.spacingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#endif
