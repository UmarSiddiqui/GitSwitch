import Foundation

/// Runs shell commands asynchronously on a background queue.
enum ShellRunner {

    /// Runs a command and returns (stdout, exitCode).
    static func run(_ arguments: [String]) async -> (output: String?, exitCode: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                task.arguments = arguments

                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = FileHandle.nullDevice

                do {
                    try task.run()
                    task.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(returning: (output?.isEmpty == false ? output : nil, task.terminationStatus))
                } catch {
                    continuation.resume(returning: (nil, -1))
                }
            }
        }
    }

    /// Convenience: returns true if exit code is 0.
    static func runSuccess(_ arguments: [String]) async -> Bool {
        let (_, exitCode) = await run(arguments)
        return exitCode == 0
    }
}
