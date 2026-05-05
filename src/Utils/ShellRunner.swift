import Foundation

/// Result of running a subprocess via `/usr/bin/env`.
struct ShellRunResult: Sendable {
    let standardOutput: String?
    let standardError: String?
    let exitCode: Int32
}

/// Runs shell commands asynchronously on a background queue.
enum ShellRunner {

    /// Runs a command and returns stdout, stderr, and exit code.
    static func run(_ arguments: [String]) async -> ShellRunResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                task.arguments = arguments

                let outPipe = Pipe()
                let errPipe = Pipe()
                task.standardOutput = outPipe
                task.standardError = errPipe

                do {
                    try task.run()
                    task.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdout = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let stderr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

                    continuation.resume(returning: ShellRunResult(
                        standardOutput: stdout.flatMap { $0.isEmpty ? nil : $0 },
                        standardError: stderr.flatMap { $0.isEmpty ? nil : $0 },
                        exitCode: task.terminationStatus
                    ))
                } catch {
                    continuation.resume(returning: ShellRunResult(
                        standardOutput: nil,
                        standardError: error.localizedDescription,
                        exitCode: -1
                    ))
                }
            }
        }
    }

    /// Convenience: returns true if exit code is 0.
    static func runSuccess(_ arguments: [String]) async -> Bool {
        let r = await run(arguments)
        return r.exitCode == 0
    }
}
