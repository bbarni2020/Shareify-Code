import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var aiEnabled: Bool
    @State private var username = "Guest"
    @State private var isLoggedIn = false
    @State private var showLoginSheet = false
    @State private var serverUsername = ""
    @State private var isServerConnected = false
    @State private var showServerLogin = false
    
    let appVersion = "1.0.0"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: Theme.animationNormal, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.appSurfaceElevated)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.vertical, Theme.spacingL)
            .background(
                Color.appSurface
                    .overlay(
                        Rectangle()
                            .fill(Color.appBorderSubtle)
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    )
            )
            
            ScrollView {
                VStack(spacing: Theme.spacingXL) {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("Shareify Account")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: Theme.spacingM) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                
                                if isLoggedIn {
                                    Text(username.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color.appAccent)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color.appTextTertiary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                Text(isLoggedIn ? username : "Not signed in")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                
                                Text(isLoggedIn ? "Shareify Pro" : "Sign in to sync your work")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if isLoggedIn {
                                    isLoggedIn = false
                                    username = "Guest"
                                } else {
                                    showLoginSheet = true
                                }
                            }) {
                                Text(isLoggedIn ? "Sign Out" : "Sign In")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .padding(.horizontal, Theme.spacingL)
                                    .padding(.vertical, Theme.spacingS)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                            .fill(Color.appSurfaceElevated)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                            .stroke(Color.appBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(Theme.spacingL)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("AI Features")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                            .textCase(.uppercase)
                        
                        HStack {
                            HStack(spacing: Theme.spacingM) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                        .fill(Color.appAccent.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.appAccent)
                                }
                                
                                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                    Text("Enable AI Assistant")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.appTextPrimary)
                                    
                                    Text("SharAI coding assistant")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $aiEnabled)
                                .labelsHidden()
                                .tint(Color.appAccent)
                        }
                        .padding(Theme.spacingL)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("Server Connection")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: Theme.spacingM) {
                            HStack(spacing: Theme.spacingM) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                        .fill(isServerConnected ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: isServerConnected ? "server.rack" : "server.rack.badge.xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(isServerConnected ? Color.green : Color.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                    Text(isServerConnected ? "Server Connected" : "No Server Connection")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.appTextPrimary)
                                    
                                    Text(isServerConnected ? serverUsername : "Optional: Connect to your server")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                                
                                Spacer()
                                
                                if isServerConnected {
                                    Button(action: {
                                        disconnectServer()
                                    }) {
                                        Text("Disconnect")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.appTextPrimary)
                                            .padding(.horizontal, Theme.spacingL)
                                            .padding(.vertical, Theme.spacingS)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                                    .fill(Color.appSurfaceElevated)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                                    .stroke(Color.appBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                } else if isLoggedIn {
                                    Button(action: {
                                        showServerLogin = true
                                    }) {
                                        Text("Connect")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.white)
                                            .padding(.horizontal, Theme.spacingL)
                                            .padding(.vertical, Theme.spacingS)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                                    .fill(Color.appAccent)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(Theme.spacingL)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .fill(Color.appSurfaceElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            
                            if !isLoggedIn {
                                HStack(spacing: Theme.spacingS) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.appTextTertiary)
                                    Text("Sign in to Shareify first to enable server connection")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.appTextTertiary)
                                }
                                .padding(.horizontal, Theme.spacingM)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("About")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appTextPrimary)
                                
                                Spacer()
                                
                                Text(appVersion)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .padding(Theme.spacingL)
                            
                            // removed check for updates entry as requested
                        }
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(Theme.spacingXL)
            }
        }
        .frame(width: 520, height: 600)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 40, x: 0, y: 20)
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(
                isPresented: $showLoginSheet,
                onLogin: { user in
                    username = user
                    isLoggedIn = true
                }
            )
        }
        .sheet(isPresented: $showServerLogin) {
            ServerLoginSheet(
                isPresented: $showServerLogin,
                onConnect: { serverUser in
                    serverUsername = serverUser
                    isServerConnected = true
                }
            )
        }
        .onAppear {
            loadUserState()
        }
    }
    
    private func loadUserState() {
        if let email = UserDefaults.standard.string(forKey: "user_email"), !email.isEmpty {
            username = email
            isLoggedIn = true
        }
        
        if let serverUser = UserDefaults.standard.string(forKey: "server_username"), !serverUser.isEmpty,
           UserDefaults.standard.string(forKey: "shareify_jwt") != nil {
            serverUsername = serverUser
            isServerConnected = true
        }
    }
    
    private func disconnectServer() {
        UserDefaults.standard.removeObject(forKey: "server_username")
        UserDefaults.standard.removeObject(forKey: "server_password")
        UserDefaults.standard.removeObject(forKey: "shareify_jwt")
        UserDefaults.standard.synchronize()
        
        serverUsername = ""
        isServerConnected = false
    }
}

struct LoginSheet: View {
    @Binding var isPresented: Bool
    let onLogin: (String) -> Void
    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
            VStack(spacing: Theme.spacingXL) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                
                Text("Sign In to Shareify")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Access your workspace from anywhere")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
            }
            
            VStack(spacing: Theme.spacingM) {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Email")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                    
                    TextField("Enter email", text: $emailInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: Theme.uiFontSize))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingM)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .stroke(focusedField == .email ? Color.appAccent.opacity(0.5) : Color.appBorder, lineWidth: 1)
                        )
                        .focused($focusedField, equals: .email)
                }
                
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                    
                    SecureField("Enter password", text: $passwordInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: Theme.uiFontSize))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingM)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .stroke(focusedField == .password ? Color.appAccent.opacity(0.5) : Color.appBorder, lineWidth: 1)
                        )
                        .focused($focusedField, equals: .password)
                }
                
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            HStack(spacing: Theme.spacingM) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                
                Button(action: {
                    performLogin()
                }) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Signing In..." : "Sign In")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(emailInput.isEmpty || isLoading ? Color.appTextTertiary : Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(emailInput.isEmpty || isLoading ? Color.appSurfaceElevated : Color.appAccent)
                    )
                }
                .buttonStyle(.plain)
                .disabled(emailInput.isEmpty || isLoading)
            }
            
            Button(action: {
                if let url = URL(string: "https://bbarni2020.github.io/Shareify/guides/") {
                    #if os(macOS)
                    NSWorkspace.shared.open(url)
                    #else
                    UIApplication.shared.open(url)
                    #endif
                }
            }) {
                Text("Need help to signup? Click here")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.spacingXXL)
        .frame(width: 440)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 32, x: 0, y: 16)
        .onAppear {
            focusedField = .email
        }
    }
    
    func performLogin() {
        focusedField = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showError = false
            isLoading = true
        }
        
        ServerManager.shared.bridgeLogin(email: emailInput, password: passwordInput) { result in
            switch result {
            case .success(_):
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    onLogin(emailInput)
                    isPresented = false
                }
            case .failure(let error):
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ServerLoginSheet: View {
    @Binding var isPresented: Bool
    let onConnect: (String) -> Void
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            VStack(spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                
                Text("Connect to Server")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Login with your server credentials")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
            }
            
            VStack(spacing: Theme.spacingM) {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Server Username")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                    
                    TextField("Enter server username", text: $usernameInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: Theme.uiFontSize))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingM)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .stroke(focusedField == .username ? Color.appAccent.opacity(0.5) : Color.appBorder, lineWidth: 1)
                        )
                        .focused($focusedField, equals: .username)
                }
                
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Server Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                    
                    SecureField("Enter server password", text: $passwordInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: Theme.uiFontSize))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingM)
                        .background(Color.appCodeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous)
                                .stroke(focusedField == .password ? Color.appAccent.opacity(0.5) : Color.appBorder, lineWidth: 1)
                        )
                        .focused($focusedField, equals: .password)
                }
                
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            HStack(spacing: Theme.spacingM) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                .fill(Color.appSurfaceElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                
                Button(action: {
                    performServerLogin()
                }) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Connecting..." : "Connect")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(usernameInput.isEmpty || isLoading ? Color.appTextTertiary : Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                            .fill(usernameInput.isEmpty || isLoading ? Color.appSurfaceElevated : Color.appAccent)
                    )
                }
                .buttonStyle(.plain)
                .disabled(usernameInput.isEmpty || isLoading)
            }
            
            Button(action: {
                if let url = URL(string: "https://bbarni2020.github.io/Shareify/guides/") {
                    #if os(macOS)
                    NSWorkspace.shared.open(url)
                    #else
                    UIApplication.shared.open(url)
                    #endif
                }
            }) {
                Text("Need help to signup? Click here")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.spacingXXL)
        .frame(width: 440)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusXL, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Theme.panelShadow, radius: 32, x: 0, y: 16)
        .onAppear {
            focusedField = .username
        }
    }
    
    func performServerLogin() {
        focusedField = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showError = false
            isLoading = true
        }
        
        ServerManager.shared.loginToServer(username: usernameInput, password: passwordInput) { result in
            switch result {
            case .success(_):
                UserDefaults.standard.set(usernameInput, forKey: "server_username")
                UserDefaults.standard.set(passwordInput, forKey: "server_password")
                UserDefaults.standard.synchronize()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    onConnect(usernameInput)
                    isPresented = false
                }
            case .failure(let error):
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
