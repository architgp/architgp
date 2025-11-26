import SwiftUI

struct TitleScreen: View {
    @EnvironmentObject var store: DataStore
    let onLogin: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var athleteName: String = ""
    @State private var showValidationAlert = false
    @State private var showCredentialMismatch = false
    @State private var showResetSheet = false
    @State private var resetUsername: String = ""
    @State private var resetEmail: String = ""
    @State private var resetPassword: String = ""
    @State private var resetConfirmPassword: String = ""
    @State private var resetCode: String = ""
    @State private var expectedResetCode: String = ""
    @State private var resetCodeExpiresAt: Date? = nil
    @State private var resetErrorMessage: String = ""
    @State private var showResetSuccess = false
    @State private var isSendingCode = false
    @State private var codeSent = false
    @FocusState private var focusedField: Field?
    @FocusState private var resetFocusedField: ResetField?

    @AppStorage("TrainSafe_username") private var savedUsername: String = ""
    @AppStorage("TrainSafe_password") private var savedPassword: String = ""
    @AppStorage("TrainSafe_accounts") private var storedAccountsJSON: String = ""

    private enum Field: Hashable {
        case username
        case password
        case athlete
    }

    private enum ResetField: Hashable {
        case username
        case email
        case password
        case confirm
        case code
    }

    private func loadStoredAccounts() -> [String: AccountCredentials] {
        guard let data = storedAccountsJSON.data(using: .utf8), !storedAccountsJSON.isEmpty else { return [:] }
        if let decoded = try? JSONDecoder().decode([String: AccountCredentials].self, from: data) {
            return decoded
        }

        // Legacy storage migration: stored password only
        if let legacy = try? JSONDecoder().decode([String: String].self, from: data) {
            var migrated: [String: AccountCredentials] = [:]
            for (user, pass) in legacy {
                migrated[user] = AccountCredentials(password: pass, email: user.contains("@") ? user : "")
            }
            return migrated
        }

        return [:]
    }

    private func saveStoredAccounts(_ accounts: [String: AccountCredentials]) {
        guard let data = try? JSONEncoder().encode(accounts), let json = String(data: data, encoding: .utf8) else {
            storedAccountsJSON = ""
            return
        }
        storedAccountsJSON = json
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)

                        Text("TrainSafe")
                            .font(.largeTitle.weight(.bold))
                            .trainSafeVibrantText()

                        Text("Log in to manage your athlete's training load")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                    }

                    Form {
                        Section("Account") {
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .athlete }

                            Button("Forgot Password?") {
                                resetUsername = username
                                let accounts = loadStoredAccounts()
                                if let account = accounts[username.trimmingCharacters(in: .whitespacesAndNewlines)] {
                                    resetEmail = account.email
                                }
                                showResetSheet = true
                            }
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        Section("Athlete") {
                            TextField("Athlete name", text: $athleteName)
                                .focused($focusedField, equals: .athlete)
                                .submitLabel(.go)
                                .onSubmit { attemptLogin() }
                        }

                        Section {
                            Button(action: attemptLogin) {
                                Label("Continue", systemImage: "arrow.right.circle.fill")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollContentBackground(.hidden)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter your username, password, and athlete name to continue.")
        }
        .alert("Login Error", isPresented: $showCredentialMismatch) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The password you entered doesn't match this username. Please try again.")
        }
        .alert("Password Updated", isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your password has been reset. Use your new password next time you sign in.")
        }
        .onAppear {
            username = savedUsername
            password = savedPassword
            athleteName = store.athleteName
        }
        .sheet(isPresented: $showResetSheet, onDismiss: clearResetState) {
            NavigationStack {
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    Form {
                        Section("Account") {
                            TextField("Username", text: $resetUsername)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($resetFocusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { resetFocusedField = .email }

                            TextField("Recovery email", text: $resetEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($resetFocusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { resetFocusedField = .password }
                        }

                        Section("New Password") {
                            SecureField("New password", text: $resetPassword)
                                .textContentType(.newPassword)
                                .focused($resetFocusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { resetFocusedField = .confirm }
                            SecureField("Confirm password", text: $resetConfirmPassword)
                                .textContentType(.newPassword)
                                .focused($resetFocusedField, equals: .confirm)
                                .submitLabel(.done)
                                .onSubmit { handlePasswordReset() }
                        }

                        Section("Verification") {
                            HStack {
                                Button(action: sendResetCode) {
                                    Label(codeSent ? "Resend code" : "Send code", systemImage: "envelope.badge")
                                }
                                .disabled(isSendingCode || resetUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                if isSendingCode { ProgressView().padding(.leading, 8) }
                            }

                            if codeSent {
                                Text("We emailed a 6-digit code to \(resetEmail). Enter it below to confirm your reset.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            TextField("6-digit code", text: $resetCode)
                                .keyboardType(.numberPad)
                                .focused($resetFocusedField, equals: .code)
                                .submitLabel(.done)
                                .onSubmit { handlePasswordReset() }
                        }

                        if !resetErrorMessage.isEmpty {
                            Section {
                                Text(resetErrorMessage)
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollContentBackground(.hidden)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
                .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showResetSheet = false }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") { handlePasswordReset() }
                                    .disabled(resetUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resetPassword.isEmpty || resetConfirmPassword.isEmpty || resetCode.isEmpty)
                            }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { resetFocusedField = nil }
                    }
                }
                .navigationTitle("Reset Password")
            }
            .presentationDetents([.medium])
        }
    }

    private func attemptLogin() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = athleteName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !trimmedPassword.isEmpty, !trimmedName.isEmpty else {
            showValidationAlert = true
            return
        }

        var accounts = loadStoredAccounts()
        if let existingAccount = accounts[trimmedUsername], existingAccount.password != trimmedPassword {
            showCredentialMismatch = true
            focusedField = .password
            return
        }

        let recoveryEmail: String
        if let existingAccount = accounts[trimmedUsername] {
            recoveryEmail = existingAccount.email
        } else {
            recoveryEmail = trimmedUsername.contains("@") ? trimmedUsername : ""
        }

        accounts[trimmedUsername] = AccountCredentials(password: trimmedPassword, email: recoveryEmail)
        saveStoredAccounts(accounts)

        username = trimmedUsername
        password = trimmedPassword
        athleteName = trimmedName

        store.athleteName = trimmedName
        store.save()

        savedUsername = trimmedUsername
        savedPassword = trimmedPassword

        showValidationAlert = false
        showCredentialMismatch = false
        focusedField = nil
        onLogin()
    }

    private func sendResetCode() {
        let trimmedUsername = resetUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            resetErrorMessage = "Enter your username to send a code."
            resetFocusedField = .username
            return
        }

        guard !trimmedEmail.isEmpty else {
            resetErrorMessage = "Enter the recovery email for this account."
            resetFocusedField = .email
            return
        }

        var accounts = loadStoredAccounts()
        guard var account = accounts[trimmedUsername] else {
            resetErrorMessage = "No account found for that username."
            resetFocusedField = .username
            return
        }

        if !account.email.isEmpty && account.email.lowercased() != trimmedEmail.lowercased() {
            resetErrorMessage = "That email doesn't match the recovery email on file."
            resetFocusedField = .email
            return
        }

        resetErrorMessage = ""
        isSendingCode = true

        Task {
            do {
                let code = try await PasswordResetService.shared.sendResetCode(username: trimmedUsername, to: trimmedEmail)
                await MainActor.run {
                    expectedResetCode = code
                    resetCodeExpiresAt = Date().addingTimeInterval(15 * 60)
                    codeSent = true
                    isSendingCode = false

                    account.email = trimmedEmail
                    accounts[trimmedUsername] = account
                    saveStoredAccounts(accounts)
                }
            } catch {
                await MainActor.run {
                    resetErrorMessage = "Failed to send code: \(error.localizedDescription)"
                    isSendingCode = false
                }
            }
        }
    }

    private func handlePasswordReset() {
        let trimmedUsername = resetUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = resetPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = resetConfirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = resetCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            resetErrorMessage = "Enter the username for the account you want to update."
            resetFocusedField = .username
            return
        }

        guard !trimmedEmail.isEmpty else {
            resetErrorMessage = "Enter the email you use for password recovery."
            resetFocusedField = .email
            return
        }

        guard !trimmedPassword.isEmpty else {
            resetErrorMessage = "New password can't be empty."
            resetFocusedField = .password
            return
        }

        guard trimmedPassword == trimmedConfirm else {
            resetErrorMessage = "Passwords do not match."
            resetFocusedField = .confirm
            return
        }

        guard !expectedResetCode.isEmpty, !trimmedCode.isEmpty else {
            resetErrorMessage = "Request a code and enter it to confirm the reset."
            resetFocusedField = .code
            return
        }

        if let expiry = resetCodeExpiresAt, expiry < Date() {
            resetErrorMessage = "Your reset code expired. Please send a new one."
            expectedResetCode = ""
            resetFocusedField = .code
            return
        }

        guard trimmedCode == expectedResetCode else {
            resetErrorMessage = "Incorrect code. Double-check the email we sent you."
            resetFocusedField = .code
            return
        }

        var accounts = loadStoredAccounts()
        guard var account = accounts[trimmedUsername] else {
            resetErrorMessage = "No account found for that username."
            resetFocusedField = .username
            return
        }

        if !account.email.isEmpty && account.email.lowercased() != trimmedEmail.lowercased() {
            resetErrorMessage = "The recovery email doesn't match the account on file."
            resetFocusedField = .email
            return
        }

        account.password = trimmedPassword
        account.email = trimmedEmail
        accounts[trimmedUsername] = account
        saveStoredAccounts(accounts)

        if savedUsername == trimmedUsername {
            savedPassword = trimmedPassword
            password = trimmedPassword
        }

        resetErrorMessage = ""
        showResetSheet = false
        showResetSuccess = true
    }

    private func clearResetState() {
        resetUsername = ""
        resetEmail = ""
        resetPassword = ""
        resetConfirmPassword = ""
        resetCode = ""
        expectedResetCode = ""
        resetCodeExpiresAt = nil
        resetErrorMessage = ""
        resetFocusedField = nil
        isSendingCode = false
        codeSent = false
    }
}

struct WelcomeScreen: View {
    @EnvironmentObject var store: DataStore
    let onContinue: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.clear.trainSafeScreenBackground(overlay: TrainSafeTilePalette.dashboard)

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .strokeBorder(LinearGradient(colors: [.blue.opacity(0.35), .teal.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 8)
                            .frame(width: CGFloat(180 + (index * 26)), height: CGFloat(180 + (index * 26)))
                            .scaleEffect(pulse ? 1.05 : 0.85)
                            .opacity(0.4 - Double(index) * 0.1)
                            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(Double(index) * 0.12), value: pulse)
                    }

                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                        Text("Welcome to TrainSafe")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                        Text(store.displayAthleteName)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.black.opacity(0.85))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("You're all set!")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black)
                    Label("Track training load and see your dashboard insights instantly.", systemImage: "waveform.path.ecg")
                        .foregroundColor(.black)
                    Label("Toggle Growth on the dashboard for athletes 9–16 to unlock height trends.", systemImage: "ruler")
                        .foregroundColor(.black)
                    Label("Keep logging sessions and check-ins to protect against overload.", systemImage: "shield")
                        .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(TrainSafeTilePalette.dashboard.opacity(0.85)))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 8)

                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        Text("Continue to Dashboard")
                            .font(.headline.weight(.bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2.weight(.semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: 0x2DB2FF), Color(hex: 0x38D39F)], startPoint: .leading, endPoint: .trailing))
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            pulse = true
        }
    }
}

struct TitleScreen_Previews: PreviewProvider {
    static var previews: some View {
        TitleScreen(onLogin: {})
            .environmentObject(DataStore())
    }
}
