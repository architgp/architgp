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
    @State private var resetPassword: String = ""
    @State private var resetConfirmPassword: String = ""
    @State private var resetErrorMessage: String = ""
    @State private var showResetSuccess = false
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
        case password
        case confirm
    }

    private func loadStoredAccounts() -> [String: String] {
        guard let data = storedAccountsJSON.data(using: .utf8), !storedAccountsJSON.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private func saveStoredAccounts(_ accounts: [String: String]) {
        guard let data = try? JSONEncoder().encode(accounts), let json = String(data: data, encoding: .utf8) else {
            storedAccountsJSON = ""
            return
        }
        storedAccountsJSON = json
    }

    var body: some View {
        NavigationStack {
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

                    Text("Log in to manage your athlete's training load")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
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
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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
                    Form {
                        Section("Account") {
                            TextField("Username", text: $resetUsername)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($resetFocusedField, equals: .username)
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

                        if !resetErrorMessage.isEmpty {
                            Section {
                                Text(resetErrorMessage)
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showResetSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { handlePasswordReset() }
                                .disabled(resetUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resetPassword.isEmpty || resetConfirmPassword.isEmpty)
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
        if let existingPassword = accounts[trimmedUsername], existingPassword != trimmedPassword {
            showCredentialMismatch = true
            focusedField = .password
            return
        }

        accounts[trimmedUsername] = trimmedPassword
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

    private func handlePasswordReset() {
        let trimmedUsername = resetUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = resetPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = resetConfirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            resetErrorMessage = "Enter the username for the account you want to update."
            resetFocusedField = .username
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

        var accounts = loadStoredAccounts()
        guard accounts.keys.contains(trimmedUsername) else {
            resetErrorMessage = "No account found for that username."
            resetFocusedField = .username
            return
        }

        accounts[trimmedUsername] = trimmedPassword
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
        resetPassword = ""
        resetConfirmPassword = ""
        resetErrorMessage = ""
        resetFocusedField = nil
    }
}

struct TitleScreen_Previews: PreviewProvider {
    static var previews: some View {
        TitleScreen(onLogin: {})
            .environmentObject(DataStore())
    }
}
