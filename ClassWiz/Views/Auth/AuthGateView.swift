// AuthGateView.swift
// ClassWiz – Views/Auth
//
// Beautiful entry point: animated background, Sign In / Sign Up tabs,
// eye-icon password reveal, admin toggle.

import SwiftUI

// MARK: - AuthGateView

struct AuthGateView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()

    @State private var selectedTab: AuthTab = .login
    @State private var isAdminMode = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var orb1Scale: CGFloat = 1.0
    @State private var orb2Scale: CGFloat = 1.0
    @State private var orb3Scale: CGFloat = 1.0
    @State private var formAppeared = false
    @FocusState private var focusedField: AuthField?

    enum AuthTab: CaseIterable { case login, signUp }
    enum AuthField: Hashable { case name, email, password, confirmPassword }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundLayer(geo: geo)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        Color.clear.frame(height: geo.safeAreaInsets.top + 16)

                        logoSection
                            .padding(.bottom, 28)
                            .opacity(formAppeared ? 1 : 0)
                            .offset(y: formAppeared ? 0 : -20)

                        if isAdminMode {
                            adminBadge
                                .padding(.bottom, 10)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }

                        if !isAdminMode {
                            tabPicker
                                .padding(.horizontal, 24)
                                .padding(.bottom, 18)
                                .opacity(formAppeared ? 1 : 0)
                                .transition(.opacity)
                        }

                        formCard
                            .padding(.horizontal, 20)
                            .opacity(formAppeared ? 1 : 0)
                            .offset(y: formAppeared ? 0 : 24)

                        Color.clear.frame(height: 48)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                adminToggleButton(geo: geo)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1)) {
                formAppeared = true
            }
            startOrbAnimations()
        }
        .animation(AppTheme.defaultAnimation, value: isAdminMode)
        .animation(AppTheme.defaultAnimation, value: selectedTab)
    }

    // MARK: - Animated Background

    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
        ZStack {
            (isAdminMode
                ? LinearGradient(colors: [AppTheme.accent.opacity(0.18), AppTheme.background, AppTheme.primary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [AppTheme.primary.opacity(0.14), AppTheme.background, AppTheme.secondary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [(isAdminMode ? AppTheme.accent : AppTheme.primary).opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 130))
                .frame(width: 260, height: 260)
                .scaleEffect(orb1Scale)
                .blur(radius: 40)
                .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.22)
                .ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [AppTheme.secondary.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: 110))
                .frame(width: 220, height: 220)
                .scaleEffect(orb2Scale)
                .blur(radius: 35)
                .offset(x: geo.size.width * 0.38, y: geo.size.height * 0.38)
                .ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [AppTheme.accent.opacity(0.18), .clear], center: .center, startRadius: 0, endRadius: 80))
                .frame(width: 160, height: 160)
                .scaleEffect(orb3Scale)
                .blur(radius: 30)
                .offset(x: geo.size.width * 0.22, y: -geo.size.height * 0.05)
                .ignoresSafeArea()
        }
    }

    private func startOrbAnimations() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { orb1Scale = 1.18 }
        withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true).delay(1.0)) { orb2Scale = 1.22 }
        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(0.5)) { orb3Scale = 0.82 }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [(isAdminMode ? AppTheme.accent : AppTheme.primary).opacity(0.3), .clear],
                        center: .center, startRadius: 30, endRadius: 70))
                    .frame(width: 140, height: 140)
                    .blur(radius: 16)

                Circle()
                    .fill(isAdminMode
                          ? AnyShapeStyle(LinearGradient(colors: [AppTheme.accent, AppTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(AppTheme.primaryGradient))
                    .frame(width: 90, height: 90)
                    .shadow(color: (isAdminMode ? AppTheme.accent : AppTheme.primary).opacity(0.45), radius: 20, y: 8)

                Image(systemName: isAdminMode ? "shield.fill" : "graduationcap.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 5) {
                Text("ClassWiz")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(isAdminMode ? "Admin Portal" : "Intelligent Attendance Management")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Admin Badge

    private var adminBadge: some View {
        Label("Admin Access Mode", systemImage: "shield.checkered")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(AppTheme.accent.opacity(0.12))
                .overlay(Capsule().stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)))
    }

    // MARK: - Admin Toggle Button

    private func adminToggleButton(geo: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation(AppTheme.defaultAnimation) {
                        isAdminMode.toggle()
                        viewModel.errorMessage = nil
                        viewModel.showError = false
                        showPassword = false
                        showConfirmPassword = false
                        focusedField = nil
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isAdminMode ? "person.fill" : "shield.fill")
                            .font(.caption2.weight(.bold))
                        Text(isAdminMode ? "User" : "Admin")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(isAdminMode ? AppTheme.textSecondary : AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(isAdminMode ? AppTheme.surfaceSecondary : AppTheme.accent.opacity(0.12))
                            .overlay(Capsule().stroke(isAdminMode ? AppTheme.divider : AppTheme.accent.opacity(0.4), lineWidth: 1))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                }
                .padding(.top, geo.safeAreaInsets.top + 12)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }

    // MARK: - Tab Picker (underline style)

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach([AuthTab.login, .signUp], id: \.self) { tab in
                Button {
                    withAnimation(AppTheme.defaultAnimation) { selectedTab = tab }
                    viewModel.errorMessage = nil
                    viewModel.showError = false
                    showPassword = false
                    showConfirmPassword = false
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(tab == .login ? "Sign In" : "Sign Up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedTab == tab ? AppTheme.primary : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTab == tab ? AppTheme.primary : Color.clear)
                            .frame(height: 3)
                    }
                }
            }
        }
        .background(VStack { Spacer(); AppTheme.divider.frame(height: 1) })
    }

    // MARK: - Form Card (glass)

    @ViewBuilder
    private var formCard: some View {
        VStack(spacing: 20) {
            if viewModel.showError, let error = viewModel.errorMessage {
                errorBanner(error).offset(x: shakeOffset)
            }

            if isAdminMode {
                loginFields(isAdmin: true)
                actionButton(title: "Sign In as Admin") { viewModel.signIn(appState: appState) }
                adminFootnote
            } else if selectedTab == .login {
                loginFields(isAdmin: false)
                actionButton(title: "Sign In") { viewModel.signIn(appState: appState) }
                signUpPrompt
            } else {
                signUpFields
                actionButton(title: "Create Account") { viewModel.signUp(appState: appState) }
                approvalFootnote
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                .shadow(color: AppTheme.primary.opacity(0.10), radius: 30, y: 10)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
        .onAppear { if selectedTab == .signUp { viewModel.loadBatches() } }
    }

    // MARK: - Login Fields

    @ViewBuilder
    private func loginFields(isAdmin: Bool) -> some View {
        inputField(label: "Email", icon: "envelope.fill",
                   placeholder: isAdmin ? "admin@institution.edu" : "Enter your email",
                   text: $viewModel.email, field: .email,
                   keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never)
        passwordField(label: "Password", placeholder: "Enter your password",
                      text: $viewModel.password, field: .password,
                      isVisible: $showPassword, contentType: .password)
    }

    // MARK: - Sign Up Fields

    @ViewBuilder
    private var signUpFields: some View {
        inputField(label: "Full Name", icon: "person.fill", placeholder: "Your full name",
                   text: $viewModel.name, field: .name,
                   keyboard: .default, contentType: .name, capitalization: .words)
        inputField(label: "Email", icon: "envelope.fill", placeholder: "Enter your email",
                   text: $viewModel.email, field: .email,
                   keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never)
        passwordField(label: "Password", placeholder: "Min 6 characters",
                      text: $viewModel.password, field: .password,
                      isVisible: $showPassword, contentType: .newPassword)
        passwordField(label: "Confirm Password", placeholder: "Re-enter password",
                      text: $viewModel.confirmPassword, field: .confirmPassword,
                      isVisible: $showConfirmPassword, contentType: .newPassword)
        roleSelectorRow
        if viewModel.selectedRole == .student {
            batchPickerRow.transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Role Selector

    private var roleSelectorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("I am a")
            HStack(spacing: 10) {
                ForEach([UserRole.student, .teacher], id: \.self) { role in
                    let isSelected = viewModel.selectedRole == role
                    Button {
                        withAnimation(AppTheme.quickAnimation) { viewModel.selectedRole = role }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: role.icon).font(.caption.weight(.semibold))
                            Text(role.displayName).font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(AppTheme.surfaceSecondary.opacity(0.7))))
                        .shadow(color: isSelected ? AppTheme.primary.opacity(0.28) : .clear, radius: 8, y: 3)
                    }
                    .animation(AppTheme.quickAnimation, value: isSelected)
                }
            }
        }
    }

    // MARK: - Batch Picker

    private var batchPickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Batch")
            Menu {
                if viewModel.availableBatches.isEmpty {
                    Text("No batches available")
                } else {
                    ForEach(viewModel.availableBatches) { batch in
                        Button(batch.name) { viewModel.selectedBatchId = batch.id ?? "" }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.3.fill").foregroundStyle(AppTheme.primary).frame(width: 20)
                    Text(viewModel.availableBatches.first(where: { $0.id == viewModel.selectedBatchId })?.name
                         ?? (viewModel.availableBatches.isEmpty ? "Loading…" : "Select your batch"))
                    .foregroundStyle(viewModel.selectedBatchId.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceSecondary.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)))
            }
        }
    }

    // MARK: - Action Button

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button { focusedField = nil; action() } label: { Text(title) }
            .buttonStyle(CWPrimaryButtonStyle(isLoading: viewModel.isLoading))
            .disabled(viewModel.isLoading)
    }

    // MARK: - Footnotes

    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("New here?").foregroundStyle(AppTheme.textSecondary)
            Button("Create an account") {
                withAnimation(AppTheme.defaultAnimation) { selectedTab = .signUp }
                HapticManager.selection()
            }
            .foregroundStyle(AppTheme.primary).fontWeight(.semibold)
        }
        .font(.footnote)
    }

    private var adminFootnote: some View {
        Text("Admin accounts are provisioned by your institution.")
            .font(.caption).foregroundStyle(AppTheme.textSecondary).multilineTextAlignment(.center)
    }

    private var approvalFootnote: some View {
        Label("Account needs admin approval before access is granted.", systemImage: "info.circle")
            .font(.caption).foregroundStyle(AppTheme.textSecondary).multilineTextAlignment(.center)
    }

    // MARK: - Field Label

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    // MARK: - Input Field

    private func inputField(
        label: String, icon: String, placeholder: String,
        text: Binding<String>, field: AuthField,
        keyboard: UIKeyboardType, contentType: UITextContentType,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        let isFocused = focusedField == field
        return VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isFocused ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(width: 20)
                    .animation(AppTheme.quickAnimation, value: isFocused)
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(capitalization)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: field)
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceSecondary.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        isFocused ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(Color.clear), lineWidth: 1.5))
            )
            .shadow(color: isFocused ? AppTheme.primary.opacity(0.12) : .clear, radius: 8, y: 2)
            .animation(AppTheme.quickAnimation, value: isFocused)
        }
    }

    // MARK: - Password Field (with eye toggle)

    private func passwordField(
        label: String, placeholder: String,
        text: Binding<String>, field: AuthField,
        isVisible: Binding<Bool>, contentType: UITextContentType
    ) -> some View {
        let isFocused = focusedField == field
        return VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(isFocused ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(width: 20)
                    .animation(AppTheme.quickAnimation, value: isFocused)

                Group {
                    if isVisible.wrappedValue {
                        TextField(placeholder, text: text)
                            .textContentType(contentType)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        SecureField(placeholder, text: text)
                            .textContentType(contentType)
                    }
                }
                .focused($focusedField, equals: field)

                Button {
                    withAnimation(AppTheme.quickAnimation) { isVisible.wrappedValue.toggle() }
                    HapticManager.selection()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(isVisible.wrappedValue ? AppTheme.primary : AppTheme.textSecondary)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceSecondary.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        isFocused ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(Color.clear), lineWidth: 1.5))
            )
            .shadow(color: isFocused ? AppTheme.primary.opacity(0.12) : .clear, radius: 8, y: 2)
            .animation(AppTheme.quickAnimation, value: isFocused)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(AppTheme.critical)
            Text(message).font(.caption).foregroundStyle(AppTheme.critical).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button { withAnimation(AppTheme.quickAnimation) { viewModel.showError = false } } label: {
                Image(systemName: "xmark.circle.fill").font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.critical.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.critical.opacity(0.2), lineWidth: 1)))
        .onAppear {
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { shakeOffset = 8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeOffset = 0 }
        }
    }
}

// MARK: - Previews

#Preview("Auth Gate – Light") { AuthGateView().environmentObject(AppState()) }
#Preview("Auth Gate – Dark") { AuthGateView().environmentObject(AppState()).preferredColorScheme(.dark) }
