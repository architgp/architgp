import Foundation

struct AccountCredentials: Codable {
    var password: String
    var email: String
}

enum PasswordResetError: LocalizedError {
    case missingConfiguration
    case connectionFailed
    case handshakeFailed(String)
    case unauthorized
    case invalidRecipient
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Configure an SMTP host, from address, and password to send reset emails."
        case .connectionFailed:
            return "Could not reach the configured mail server."
        case .handshakeFailed(let detail):
            return "Secure connection failed: \(detail)."
        case .unauthorized:
            return "The mail server rejected the credentials."
        case .invalidRecipient:
            return "The recovery email address looks invalid."
        case .sendFailed(let detail):
            return "Unable to send email: \(detail)."
        }
    }
}

struct PasswordEmailConfiguration {
    var fromAddress: String
    var password: String
    var host: String
    var port: Int
    var useTLS: Bool

    static var `default`: PasswordEmailConfiguration {
        let defaults = UserDefaults.standard
        let configuredFrom = defaults.string(forKey: "TrainSafe_support_email") ?? ""
        let configuredPassword = defaults.string(forKey: "TrainSafe_support_email_password") ?? ""
        let configuredHost = defaults.string(forKey: "TrainSafe_support_email_host") ?? ""
        let configuredPort = defaults.integer(forKey: "TrainSafe_support_email_port")
        let configuredTLS = defaults.object(forKey: "TrainSafe_support_email_tls") as? Bool

        // Replace with your SMTP settings (e.g., Outlook, iCloud, custom domain).
        return PasswordEmailConfiguration(
            fromAddress: configuredFrom.isEmpty ? "support@trainsafe.app" : configuredFrom,
            password: configuredPassword.isEmpty ? "your-app-password" : configuredPassword,
            host: configuredHost.isEmpty ? "smtp.gmail.com" : configuredHost,
            port: configuredPort == 0 ? 465 : configuredPort,
            useTLS: configuredTLS ?? true
        )
    }
}

final class PasswordResetService {
    static let shared = PasswordResetService()
    private init() {}

    private let client = SMTPClient()

    func sendResetCode(username: String, to email: String) async throws -> String {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@") else { throw PasswordResetError.invalidRecipient }

        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let body = """
        Hi \(username),\n\nYour TrainSafe password reset code is: \(code)\n\nThis code expires in 15 minutes. If you didn't request this, you can ignore this email.\n\nTrainSafe Support
        """

        try await client.send(
            to: trimmedEmail,
            subject: "TrainSafe password reset code",
            body: body,
            configuration: .default
        )

        return code
    }
}

private final class SMTPClient {
    func send(to recipient: String, subject: String, body: String, configuration: PasswordEmailConfiguration) async throws {
        guard !configuration.fromAddress.isEmpty, !configuration.password.isEmpty, !configuration.host.isEmpty else {
            throw PasswordResetError.missingConfiguration
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.performSend(to: recipient, subject: subject, body: body, configuration: configuration)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performSend(to recipient: String, subject: String, body: String, configuration: PasswordEmailConfiguration) throws {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        Stream.getStreamsToHost(withName: configuration.host, port: configuration.port, inputStream: &inputStream, outputStream: &outputStream)

        guard let input = inputStream, let output = outputStream else { throw PasswordResetError.connectionFailed }

        if configuration.useTLS {
            input.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
            output.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: .socketSecurityLevelKey)
        }

        input.open(); output.open()
        defer {
            input.close(); output.close()
        }

        _ = try readResponse(from: input) // 220 greeting

        try write("EHLO trainsafe.app\r\n", to: output)
        _ = try readResponse(from: input)

        try write("AUTH LOGIN\r\n", to: output)
        let authPrompt1 = try readResponse(from: input)
        guard authPrompt1.hasPrefix("334") else { throw PasswordResetError.handshakeFailed("AUTH LOGIN not accepted") }

        try write("\(configuration.fromAddress.data(using: .utf8)!.base64EncodedString())\r\n", to: output)
        let authPrompt2 = try readResponse(from: input)
        guard authPrompt2.hasPrefix("334") else { throw PasswordResetError.unauthorized }

        try write("\(configuration.password.data(using: .utf8)!.base64EncodedString())\r\n", to: output)
        let authOK = try readResponse(from: input)
        guard authOK.hasPrefix("235") else { throw PasswordResetError.unauthorized }

        try write("MAIL FROM:<\(configuration.fromAddress)>\r\n", to: output)
        _ = try readResponse(from: input)

        try write("RCPT TO:<\(recipient)>\r\n", to: output)
        let rcpt = try readResponse(from: input)
        guard rcpt.hasPrefix("250") || rcpt.hasPrefix("251") else { throw PasswordResetError.invalidRecipient }

        try write("DATA\r\n", to: output)
        _ = try readResponse(from: input)

        let headers = [
            "From: TrainSafe Support <\(configuration.fromAddress)>",
            "To: <\(recipient)>",
            "Subject: \(subject)",
            "Content-Type: text/plain; charset=utf-8",
            ""
        ].joined(separator: "\r\n")

        try write("\(headers)\r\n\(body)\r\n.\r\n", to: output)
        let dataResponse = try readResponse(from: input)
        guard dataResponse.hasPrefix("250") else { throw PasswordResetError.sendFailed(dataResponse) }

        try write("QUIT\r\n", to: output)
    }

    private func write(_ string: String, to output: OutputStream) throws {
        guard let data = string.data(using: .utf8) else { throw PasswordResetError.sendFailed("encoding") }
        let result = data.withUnsafeBytes {
            output.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
        if result <= 0 {
            throw PasswordResetError.connectionFailed
        }
    }

    private func readResponse(from input: InputStream) throws -> String {
        var buffer = [UInt8](repeating: 0, count: 1024)
        var output = ""

        while input.hasBytesAvailable {
            let read = input.read(&buffer, maxLength: buffer.count)
            if read > 0 {
                if let chunk = String(bytes: buffer[0..<read], encoding: .utf8) {
                    output += chunk
                    if chunk.contains("\r\n") { break }
                }
            } else if read < 0 {
                throw PasswordResetError.connectionFailed
            } else {
                break
            }
        }

        return output
    }
}
