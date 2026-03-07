import Foundation

public protocol StudentReviewReportWriting {
    @discardableResult
    func write(_ report: StudentReviewReport) throws -> URL
}

public struct StudentReviewReportWriter: StudentReviewReportWriting {
    private let fileManager: FileManager
    private let reportsRootDirectory: URL
    private let encoder: JSONEncoder

    public init(
        reportsRootDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.reportsRootDirectory = reportsRootDirectory

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
    }

    @discardableResult
    public func write(_ report: StudentReviewReport) throws -> URL {
        let dateKey = Self.dateKey(from: report.startedAt)
        let dateDirectory = reportsRootDirectory.appendingPathComponent(dateKey, isDirectory: true)

        do {
            try fileManager.createDirectory(at: dateDirectory, withIntermediateDirectories: true)
        } catch {
            throw StudentReviewReportWriterError.createDirectoryFailed(path: dateDirectory.path, underlying: error)
        }

        let taskPart = report.taskId ?? "student"
        let sanitizedTaskPart = Self.sanitizeForFilename(taskPart)
        let fileName = "\(report.sessionId)-\(sanitizedTaskPart)-student-review.json"
        let fileURL = dateDirectory.appendingPathComponent(fileName, isDirectory: false)

        do {
            let data = try encoder.encode(report)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw StudentReviewReportWriterError.writeReportFailed(path: fileURL.path, underlying: error)
        }

        return fileURL
    }

    private static func dateKey(from timestamp: String) -> String {
        let pattern = "^\\d{4}-\\d{2}-\\d{2}$"
        let candidate = String(timestamp.prefix(10))
        if candidate.range(of: pattern, options: .regularExpression) != nil {
            return candidate
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func sanitizeForFilename(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let result = String(scalars)
        return result.isEmpty ? "task" : result
    }
}

public enum StudentReviewReportWriterError: LocalizedError {
    case createDirectoryFailed(path: String, underlying: Error)
    case writeReportFailed(path: String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .createDirectoryFailed(let path, let underlying):
            return "Failed to create student report directory \(path): \(underlying.localizedDescription)"
        case .writeReportFailed(let path, let underlying):
            return "Failed to write student report \(path): \(underlying.localizedDescription)"
        }
    }
}
