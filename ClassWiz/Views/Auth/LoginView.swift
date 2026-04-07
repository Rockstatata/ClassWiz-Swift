// LoginView.swift
// ClassWiz – Views/Auth

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email, password
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.08),
                    AppTheme.background,
                    AppTheme.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // MARK: - Logo Section
                    logoSection
                        .padding(.bottom, 48)

                    // MARK: - Form Section
                    formSection
                        .padding(.horizontal, AppTheme.spacingLG)

                    Spacer().frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 88, height: 88)

                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 20, y: 8)

            VStack(spacing: 4) {
                Text("ClassWiz")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Intelligent Attendance Management")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Error Banner
            if viewModel.showError, let error = viewModel.errorMessage {
                errorBanner(error)
                    .offset(x: shakeOffset)
            }

            // Email Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(focusedField == .email ? AppTheme.primary : AppTheme.textSecondary)
                        .frame(width: 20)

                    TextField("Enter your email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .email)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                        .fill(AppTheme.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                        .stroke(focusedField == .email ? AppTheme.primary : Color.clear, lineWidth: 1.5)
                )
            }

            // Password Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(focusedField == .password ? AppTheme.primary : AppTheme.textSecondary)
                        .frame(width: 20)

                    SecureField("Enter your password", text: $viewModel.password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                        .fill(AppTheme.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                        .stroke(focusedField == .password ? AppTheme.primary : Color.clear, lineWidth: 1.5)
                )
            }

            // Sign In Button
            Button {
                focusedField = nil
                viewModel.signIn(appState: appState)
            } label: {
                Text("Sign In")
            }
            .buttonStyle(CWPrimaryButtonStyle(isLoading: viewModel.isLoading))
            .disabled(viewModel.isLoading)
            .padding(.top, AppTheme.spacingSM)

            // Footer
            Text("Contact your administrator if you don't have an account.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, AppTheme.spacingSM)
        }
        .padding(AppTheme.spacingLG)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.06), radius: 20, y: 4)
        )
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.critical)

            Text(message)
                .font(.caption)
                .foregroundColor(AppTheme.critical)

            Spacer()

            Button {
                withAnimation { viewModel.showError = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSM)
                .fill(AppTheme.critical.opacity(0.08))
        )
        .onAppear {
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shakeOffset = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shakeOffset = 0
            }
        }
    }
}

#Preview("Login") {
    LoginView()
        .environmentObject(AppState())
}

#Preview("Login – Dark") {
    LoginView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
