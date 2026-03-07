import ApplicationServices
import Foundation
import SwiftUI

@main
struct OpenStaffApp: App {
    @StateObject private var viewModel = OpenStaffDashboardViewModel()

    var body: some Scene {
        WindowGroup("OpenStaff") {
            OpenStaffDashboardView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1080, height: 920)
    }
}

struct OpenStaffDashboardView: View {
    @ObservedObject var viewModel: OpenStaffDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenStaff 主界面")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("阶段 5.2：学习记录与知识浏览")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if let refreshedAt = viewModel.lastRefreshedAt {
                        Text("最近刷新：\(OpenStaffDateFormatter.displayString(from: refreshedAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Button("刷新任务与权限") {
                            viewModel.refreshDashboard(promptAccessibilityPermission: false)
                        }
                        .keyboardShortcut("r", modifiers: [.command])

                        Button("申请辅助功能权限") {
                            viewModel.refreshDashboard(promptAccessibilityPermission: true)
                        }
                    }
                }
            }

            GroupBox("模式切换") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker(
                        "运行模式",
                        selection: Binding(
                            get: { viewModel.currentMode },
                            set: { viewModel.requestModeChange(to: $0) }
                        )
                    ) {
                        ForEach(OpenStaffMode.allCases, id: \.self) { mode in
                            Text(viewModel.modeDisplayName(for: mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("切换守卫输入")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                        GridRow {
                            Toggle("老师已确认", isOn: $viewModel.guardInputs.teacherConfirmed)
                            Toggle("知识已就绪", isOn: $viewModel.guardInputs.learnedKnowledgeReady)
                        }
                        GridRow {
                            Toggle("执行计划已就绪", isOn: $viewModel.guardInputs.executionPlanReady)
                            Toggle("存在待确认建议", isOn: $viewModel.guardInputs.pendingAssistSuggestion)
                        }
                        GridRow {
                            Toggle("紧急停止已激活", isOn: $viewModel.guardInputs.emergencyStopActive)
                            Spacer(minLength: 0)
                        }
                    }

                    if let transitionMessage = viewModel.transitionMessage {
                        Text(transitionMessage)
                            .font(.caption)
                            .foregroundStyle(viewModel.lastTransitionAccepted ? .green : .red)
                    }
                }
                .padding(.top, 4)
            }

            HStack(alignment: .top, spacing: 12) {
                GroupBox("当前状态") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("当前模式", value: viewModel.modeDisplayName(for: viewModel.currentMode))
                        LabeledContent("状态码", value: viewModel.currentStatusCode)
                        if !viewModel.currentCapabilities.isEmpty {
                            LabeledContent("能力白名单", value: viewModel.currentCapabilities.joined(separator: ", "))
                        }
                        if !viewModel.unmetRequirementsText.isEmpty {
                            LabeledContent("未满足守卫", value: viewModel.unmetRequirementsText)
                        }
                    }
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("权限状态") {
                    VStack(alignment: .leading, spacing: 8) {
                        PermissionRow(
                            title: "辅助功能权限",
                            granted: viewModel.permissionSnapshot.accessibilityTrusted
                        )
                        PermissionRow(
                            title: "数据目录可写",
                            granted: viewModel.permissionSnapshot.dataDirectoryWritable
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }

            GroupBox("最近任务") {
                if viewModel.recentTasks.isEmpty {
                    Text("暂无最近任务记录。可先运行一次教学/辅助/学生流程后刷新。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    List(viewModel.recentTasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(viewModel.modeDisplayName(for: task.mode))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(task.mode.color)
                                Text(task.taskId)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(OpenStaffDateFormatter.displayString(from: task.timestamp))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(task.message)
                                .font(.callout)
                            Text("status: \(task.status) · session: \(task.sessionId)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 260)
                }
            }

            GroupBox("学习记录与知识浏览") {
                if viewModel.learningSessions.isEmpty {
                    Text("暂无学习会话数据。可先运行 capture/slice/knowledge，再点击刷新。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("会话列表")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            List(
                                selection: Binding(
                                    get: { viewModel.selectedLearningSessionId },
                                    set: { viewModel.selectLearningSession($0) }
                                )
                            ) {
                                ForEach(viewModel.learningSessions) { session in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.sessionId)
                                            .font(.callout)
                                        Text("任务 \(session.taskCount) · 知识 \(session.knowledgeItemCount)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        if let endedAt = session.endedAt {
                                            Text("最近活动：\(OpenStaffDateFormatter.displayString(from: endedAt))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    .tag(session.sessionId as String?)
                                }
                            }
                            .listStyle(.inset)
                            .frame(minWidth: 260, minHeight: 280)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("任务列表")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if viewModel.tasksForSelectedSession.isEmpty {
                                Text("该会话暂无任务。")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .padding(.top, 8)
                            } else {
                                List(
                                    selection: Binding(
                                        get: { viewModel.selectedLearningTaskId },
                                        set: { viewModel.selectLearningTask($0) }
                                    )
                                ) {
                                    ForEach(viewModel.tasksForSelectedSession) { task in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.taskId)
                                                .font(.callout)
                                            HStack(spacing: 6) {
                                                if let eventCount = task.eventCount {
                                                    Text("事件 \(eventCount)")
                                                }
                                                if let stepCount = task.knowledgeStepCount {
                                                    Text("步骤 \(stepCount)")
                                                }
                                                if let boundary = task.boundaryReason {
                                                    Text("边界 \(boundary)")
                                                }
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                        .tag(task.id as String?)
                                    }
                                }
                                .listStyle(.inset)
                            }
                        }
                        .frame(minWidth: 280, minHeight: 280)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("任务详情与知识条目")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let detail = viewModel.selectedTaskDetail {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        LabeledContent("任务 ID", value: detail.task.taskId)
                                        LabeledContent("会话 ID", value: detail.task.sessionId)
                                        if let appName = detail.task.appName {
                                            LabeledContent("应用", value: appName)
                                        }
                                        if let startedAt = detail.task.startedAt {
                                            LabeledContent("开始时间", value: OpenStaffDateFormatter.displayString(from: startedAt))
                                        }
                                        if let endedAt = detail.task.endedAt {
                                            LabeledContent("结束时间", value: OpenStaffDateFormatter.displayString(from: endedAt))
                                        }
                                        if let boundaryReason = detail.task.boundaryReason {
                                            LabeledContent("切片边界", value: boundaryReason)
                                        }

                                        Divider()

                                        if let knowledge = detail.knowledgeItem {
                                            LabeledContent("知识条目 ID", value: knowledge.knowledgeItemId)
                                            LabeledContent("目标", value: knowledge.goal)
                                            LabeledContent("摘要", value: knowledge.summary)
                                            LabeledContent("上下文应用", value: knowledge.contextAppName)
                                            if let windowTitle = knowledge.windowTitle,
                                               !windowTitle.isEmpty {
                                                LabeledContent("窗口标题", value: windowTitle)
                                            }
                                            if let createdAt = knowledge.createdAt {
                                                LabeledContent("生成时间", value: OpenStaffDateFormatter.displayString(from: createdAt))
                                            }
                                            if !knowledge.constraints.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("约束")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                    ForEach(knowledge.constraints) { constraint in
                                                        Text("• [\(constraint.type)] \(constraint.description)")
                                                            .font(.caption)
                                                    }
                                                }
                                            }
                                            if !knowledge.steps.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("步骤")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                    ForEach(knowledge.steps) { step in
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("\(step.stepId): \(step.instruction)")
                                                                .font(.caption)
                                                            if !step.sourceEventIds.isEmpty {
                                                                Text("source: \(step.sourceEventIds.joined(separator: ", "))")
                                                                    .font(.caption2)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            Text("该任务暂无知识条目。")
                                                .font(.callout)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                Text("请选择一个任务查看详情。")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .padding(.top, 8)
                            }
                        }
                        .frame(minWidth: 360, minHeight: 280)
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 980, minHeight: 920)
        .task {
            viewModel.refreshDashboard(promptAccessibilityPermission: false)
        }
    }
}

struct PermissionRow: View {
    let title: String
    let granted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(granted ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text(granted ? "已授权" : "未授权")
                .foregroundStyle(granted ? .green : .red)
        }
        .font(.callout)
    }
}

@MainActor
final class OpenStaffDashboardViewModel: ObservableObject {
    @Published var currentMode: OpenStaffMode
    @Published var guardInputs = ModeGuardInput()
    @Published private(set) var transitionMessage: String?
    @Published private(set) var lastDecision: ModeTransitionDecision?
    @Published private(set) var permissionSnapshot: PermissionSnapshot
    @Published private(set) var recentTasks: [RecentTaskSummary]
    @Published private(set) var learningSessions: [LearningSessionSummary]
    @Published var selectedLearningSessionId: String?
    @Published var selectedLearningTaskId: String?
    @Published private(set) var lastRefreshedAt: Date?

    private let logger = InMemoryOrchestratorStateLogger()
    private let stateMachine: ModeStateMachine
    private let sessionId: String
    private var traceSequence = 0
    private var learningSnapshot = LearningSnapshot.empty

    init(initialMode: OpenStaffMode = .teaching) {
        self.currentMode = initialMode
        self.permissionSnapshot = .unknown
        self.recentTasks = []
        self.learningSessions = []
        self.stateMachine = ModeStateMachine(initialMode: initialMode, logger: logger)
        self.sessionId = "session-gui-\(UUID().uuidString.prefix(8).lowercased())"
    }

    var lastTransitionAccepted: Bool {
        lastDecision?.accepted ?? true
    }

    var currentStatusCode: String {
        if let lastDecision {
            return lastDecision.status.rawValue
        }
        return OrchestratorStatusCode.modeStable.rawValue
    }

    var currentCapabilities: [String] {
        stateMachine.allowedCapabilities(for: currentMode).map(\.rawValue).sorted()
    }

    var unmetRequirementsText: String {
        guard let lastDecision, !lastDecision.unmetRequirements.isEmpty else {
            return ""
        }
        return lastDecision.unmetRequirements.map(\.rawValue).joined(separator: ", ")
    }

    var tasksForSelectedSession: [LearningTaskSummary] {
        guard let selectedLearningSessionId else {
            return []
        }
        return learningSnapshot.tasksBySession[selectedLearningSessionId] ?? []
    }

    var selectedTaskDetail: LearningTaskDetail? {
        guard let selectedLearningTaskId else {
            return nil
        }
        return learningSnapshot.taskDetailsById[selectedLearningTaskId]
    }

    func modeDisplayName(for mode: OpenStaffMode) -> String {
        switch mode {
        case .teaching:
            return "教学模式"
        case .assist:
            return "辅助模式"
        case .student:
            return "学生模式"
        }
    }

    func requestModeChange(to targetMode: OpenStaffMode) {
        guard targetMode != currentMode else {
            return
        }

        traceSequence += 1
        let timestamp = OpenStaffDateFormatter.iso8601String(from: Date())
        let context = ModeTransitionContext(
            traceId: "trace-gui-\(traceSequence)",
            sessionId: sessionId,
            timestamp: timestamp,
            teacherConfirmed: guardInputs.teacherConfirmed,
            learnedKnowledgeReady: guardInputs.learnedKnowledgeReady,
            executionPlanReady: guardInputs.executionPlanReady,
            pendingAssistSuggestion: guardInputs.pendingAssistSuggestion,
            emergencyStopActive: guardInputs.emergencyStopActive
        )
        let decision = stateMachine.transition(to: targetMode, context: context)
        lastDecision = decision
        currentMode = stateMachine.currentMode
        transitionMessage = decision.message
    }

    func refreshDashboard(promptAccessibilityPermission: Bool) {
        permissionSnapshot = PermissionSnapshot.capture(promptAccessibilityPermission: promptAccessibilityPermission)
        recentTasks = RecentTaskRepository.loadRecentTasks(limit: 8)
        learningSnapshot = LearningRecordRepository.loadLearningSnapshot()
        learningSessions = learningSnapshot.sessions
        reconcileLearningSelection()
        lastRefreshedAt = Date()
    }

    func selectLearningSession(_ sessionId: String?) {
        selectedLearningSessionId = sessionId
        reconcileTaskSelectionForCurrentSession()
    }

    func selectLearningTask(_ taskId: String?) {
        selectedLearningTaskId = taskId
    }

    private func reconcileLearningSelection() {
        let sessionIds = Set(learningSessions.map(\.sessionId))
        if let selectedLearningSessionId, !sessionIds.contains(selectedLearningSessionId) {
            self.selectedLearningSessionId = nil
        }
        if self.selectedLearningSessionId == nil {
            self.selectedLearningSessionId = learningSessions.first?.sessionId
        }
        reconcileTaskSelectionForCurrentSession()
    }

    private func reconcileTaskSelectionForCurrentSession() {
        let tasks = tasksForSelectedSession
        let taskIds = Set(tasks.map(\.id))
        if let selectedLearningTaskId, !taskIds.contains(selectedLearningTaskId) {
            self.selectedLearningTaskId = nil
        }
        if self.selectedLearningTaskId == nil {
            self.selectedLearningTaskId = tasks.first?.id
        }
    }
}

struct ModeGuardInput {
    var teacherConfirmed = true
    var learnedKnowledgeReady = true
    var executionPlanReady = true
    var pendingAssistSuggestion = false
    var emergencyStopActive = false
}

struct PermissionSnapshot {
    let accessibilityTrusted: Bool
    let dataDirectoryWritable: Bool

    static let unknown = PermissionSnapshot(accessibilityTrusted: false, dataDirectoryWritable: false)

    static func capture(promptAccessibilityPermission: Bool) -> PermissionSnapshot {
        let checker = AccessibilityPermissionChecker()
        let trusted = checker.isTrusted(prompt: promptAccessibilityPermission)
        let writable = OpenStaffWorkspacePaths.ensureDataDirectoryWritable()
        return PermissionSnapshot(accessibilityTrusted: trusted, dataDirectoryWritable: writable)
    }
}

struct AccessibilityPermissionChecker {
    func isTrusted(prompt: Bool) -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

struct RecentTaskSummary: Identifiable {
    let mode: OpenStaffMode
    let sessionId: String
    let taskId: String
    let status: String
    let message: String
    let timestamp: Date

    var id: String {
        "\(mode.rawValue)|\(sessionId)|\(taskId)|\(status)"
    }
}

enum RecentTaskRepository {
    private static let decoder = JSONDecoder()

    static func loadRecentTasks(limit: Int) -> [RecentTaskSummary] {
        let logTasks = loadRecentTasksFromLogs()
        let knowledgeTasks = loadRecentTasksFromKnowledge()
        let merged = mergeLatestByTask(logTasks + knowledgeTasks)
        return Array(merged.prefix(limit))
    }

    private static func loadRecentTasksFromLogs() -> [RecentTaskSummary] {
        let logsRoot = OpenStaffWorkspacePaths.logsDirectory
        let logFiles = listFiles(withExtension: "log", under: logsRoot)
        guard !logFiles.isEmpty else {
            return []
        }

        var tasks: [RecentTaskSummary] = []
        tasks.reserveCapacity(64)

        for fileURL in logFiles {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }
            for line in content.split(whereSeparator: \.isNewline) {
                guard let data = line.data(using: .utf8),
                      let logEntry = try? decoder.decode(RecentTaskLogEntry.self, from: data),
                      let taskId = logEntry.taskId,
                      let timestamp = OpenStaffDateFormatter.date(from: logEntry.timestamp) else {
                    continue
                }

                let mode = inferMode(component: logEntry.component)
                let summary = RecentTaskSummary(
                    mode: mode,
                    sessionId: logEntry.sessionId,
                    taskId: taskId,
                    status: logEntry.status,
                    message: logEntry.message,
                    timestamp: timestamp
                )
                tasks.append(summary)
            }
        }

        return tasks
    }

    private static func loadRecentTasksFromKnowledge() -> [RecentTaskSummary] {
        let knowledgeRoot = OpenStaffWorkspacePaths.knowledgeDirectory
        let knowledgeFiles = listFiles(withExtension: "json", under: knowledgeRoot)
        guard !knowledgeFiles.isEmpty else {
            return []
        }

        var tasks: [RecentTaskSummary] = []
        tasks.reserveCapacity(16)

        for fileURL in knowledgeFiles {
            guard let data = try? Data(contentsOf: fileURL),
                  let item = try? decoder.decode(RecentKnowledgeItem.self, from: data),
                  let timestamp = OpenStaffDateFormatter.date(from: item.createdAt) else {
                continue
            }

            let summary = RecentTaskSummary(
                mode: .teaching,
                sessionId: item.sessionId,
                taskId: item.taskId,
                status: "STATUS_KNO_KNOWLEDGE_READY",
                message: item.summary,
                timestamp: timestamp
            )
            tasks.append(summary)
        }

        return tasks
    }

    private static func mergeLatestByTask(_ tasks: [RecentTaskSummary]) -> [RecentTaskSummary] {
        var latestByKey: [String: RecentTaskSummary] = [:]
        latestByKey.reserveCapacity(tasks.count)

        for task in tasks {
            let key = "\(task.mode.rawValue)|\(task.sessionId)|\(task.taskId)"
            guard let existing = latestByKey[key] else {
                latestByKey[key] = task
                continue
            }
            if task.timestamp > existing.timestamp {
                latestByKey[key] = task
            }
        }

        return latestByKey
            .values
            .sorted { lhs, rhs in
                lhs.timestamp > rhs.timestamp
            }
    }

    private static func inferMode(component: String?) -> OpenStaffMode {
        let componentValue = component ?? ""
        if componentValue.contains("student") {
            return .student
        }
        if componentValue.contains("assist") {
            return .assist
        }
        return .teaching
    }

    private static func listFiles(withExtension pathExtension: String, under root: URL) -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: root.path) else {
            return []
        }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == pathExtension {
            urls.append(fileURL)
        }
        return urls
    }
}

private struct RecentTaskLogEntry: Decodable {
    let timestamp: String
    let sessionId: String
    let taskId: String?
    let status: String
    let message: String
    let component: String?
}

private struct RecentKnowledgeItem: Decodable {
    let taskId: String
    let sessionId: String
    let summary: String
    let createdAt: String
}

struct LearningSessionSummary: Identifiable {
    let sessionId: String
    let startedAt: Date?
    let endedAt: Date?
    let taskCount: Int
    let knowledgeItemCount: Int

    var id: String {
        sessionId
    }
}

struct LearningTaskSummary: Identifiable {
    let taskId: String
    let sessionId: String
    let startedAt: Date?
    let endedAt: Date?
    let eventCount: Int?
    let boundaryReason: String?
    let appName: String?
    let knowledgeStepCount: Int?

    var id: String {
        "\(sessionId)|\(taskId)"
    }
}

struct LearningTaskDetail {
    let task: LearningTaskSummary
    let knowledgeItem: LearningKnowledgeItemDetail?
}

struct LearningKnowledgeItemDetail {
    let knowledgeItemId: String
    let goal: String
    let summary: String
    let contextAppName: String
    let contextBundleId: String
    let windowTitle: String?
    let createdAt: Date?
    let constraints: [LearningKnowledgeConstraint]
    let steps: [LearningKnowledgeStep]
}

struct LearningKnowledgeConstraint: Identifiable {
    let type: String
    let description: String

    var id: String {
        "\(type)|\(description)"
    }
}

struct LearningKnowledgeStep: Identifiable {
    let stepId: String
    let instruction: String
    let sourceEventIds: [String]

    var id: String {
        stepId
    }
}

struct LearningSnapshot {
    let sessions: [LearningSessionSummary]
    let tasksBySession: [String: [LearningTaskSummary]]
    let taskDetailsById: [String: LearningTaskDetail]

    static let empty = LearningSnapshot(sessions: [], tasksBySession: [:], taskDetailsById: [:])
}

enum LearningRecordRepository {
    private static let decoder = JSONDecoder()

    static func loadLearningSnapshot() -> LearningSnapshot {
        let chunkRecords = loadTaskChunkRecords()
        let knowledgeRecords = loadKnowledgeRecords()
        let knowledgeByTask = buildKnowledgeByTask(records: knowledgeRecords)

        var tasksBySession: [String: [LearningTaskSummary]] = [:]
        var taskDetailsById: [String: LearningTaskDetail] = [:]
        var sessionAggregates: [String: LearningSessionAggregate] = [:]

        for chunk in chunkRecords {
            let knowledge = knowledgeByTask[chunk.taskId]
            let task = LearningTaskSummary(
                taskId: chunk.taskId,
                sessionId: chunk.sessionId,
                startedAt: OpenStaffDateFormatter.date(from: chunk.startTimestamp),
                endedAt: OpenStaffDateFormatter.date(from: chunk.endTimestamp),
                eventCount: chunk.eventCount,
                boundaryReason: chunk.boundaryReason,
                appName: chunk.primaryContext.appName,
                knowledgeStepCount: knowledge?.steps.count
            )
            tasksBySession[chunk.sessionId, default: []].append(task)
            taskDetailsById[task.id] = LearningTaskDetail(task: task, knowledgeItem: mapKnowledgeDetail(knowledge))

            var aggregate = sessionAggregates[chunk.sessionId] ?? LearningSessionAggregate(sessionId: chunk.sessionId)
            aggregate.include(task: task, hasKnowledgeItem: knowledge != nil)
            sessionAggregates[chunk.sessionId] = aggregate
        }

        for knowledge in knowledgeRecords where taskDetailsById["\(knowledge.sessionId)|\(knowledge.taskId)"] == nil {
            let task = LearningTaskSummary(
                taskId: knowledge.taskId,
                sessionId: knowledge.sessionId,
                startedAt: nil,
                endedAt: OpenStaffDateFormatter.date(from: knowledge.createdAt),
                eventCount: nil,
                boundaryReason: nil,
                appName: knowledge.context.appName,
                knowledgeStepCount: knowledge.steps.count
            )
            tasksBySession[knowledge.sessionId, default: []].append(task)
            taskDetailsById[task.id] = LearningTaskDetail(task: task, knowledgeItem: mapKnowledgeDetail(knowledge))

            var aggregate = sessionAggregates[knowledge.sessionId] ?? LearningSessionAggregate(sessionId: knowledge.sessionId)
            aggregate.include(task: task, hasKnowledgeItem: true)
            sessionAggregates[knowledge.sessionId] = aggregate
        }

        let sortedTasksBySession = tasksBySession.mapValues { tasks in
            tasks.sorted { lhs, rhs in
                let lhsDate = lhs.endedAt ?? lhs.startedAt ?? Date.distantPast
                let rhsDate = rhs.endedAt ?? rhs.startedAt ?? Date.distantPast
                if lhsDate == rhsDate {
                    return lhs.taskId < rhs.taskId
                }
                return lhsDate > rhsDate
            }
        }

        let sessions = sessionAggregates
            .values
            .map { aggregate in
                LearningSessionSummary(
                    sessionId: aggregate.sessionId,
                    startedAt: aggregate.startedAt,
                    endedAt: aggregate.endedAt,
                    taskCount: aggregate.taskIds.count,
                    knowledgeItemCount: aggregate.knowledgeTaskIds.count
                )
            }
            .sorted { lhs, rhs in
                let lhsDate = lhs.endedAt ?? lhs.startedAt ?? Date.distantPast
                let rhsDate = rhs.endedAt ?? rhs.startedAt ?? Date.distantPast
                if lhsDate == rhsDate {
                    return lhs.sessionId < rhs.sessionId
                }
                return lhsDate > rhsDate
            }

        return LearningSnapshot(
            sessions: sessions,
            tasksBySession: sortedTasksBySession,
            taskDetailsById: taskDetailsById
        )
    }

    private static func loadTaskChunkRecords() -> [TaskChunkRecord] {
        let chunkFiles = listFiles(withExtension: "json", under: OpenStaffWorkspacePaths.taskChunksDirectory)
        guard !chunkFiles.isEmpty else {
            return []
        }

        var records: [TaskChunkRecord] = []
        records.reserveCapacity(chunkFiles.count)

        for fileURL in chunkFiles {
            guard let data = try? Data(contentsOf: fileURL),
                  let record = try? decoder.decode(TaskChunkRecord.self, from: data) else {
                continue
            }
            records.append(record)
        }
        return records
    }

    private static func loadKnowledgeRecords() -> [KnowledgeItemRecord] {
        let files = listFiles(withExtension: "json", under: OpenStaffWorkspacePaths.knowledgeDirectory)
        guard !files.isEmpty else {
            return []
        }

        var records: [KnowledgeItemRecord] = []
        records.reserveCapacity(files.count)

        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL),
                  let record = try? decoder.decode(KnowledgeItemRecord.self, from: data) else {
                continue
            }
            records.append(record)
        }
        return records
    }

    private static func buildKnowledgeByTask(records: [KnowledgeItemRecord]) -> [String: KnowledgeItemRecord] {
        var byTask: [String: KnowledgeItemRecord] = [:]
        byTask.reserveCapacity(records.count)

        for item in records {
            guard let existing = byTask[item.taskId] else {
                byTask[item.taskId] = item
                continue
            }

            let existingDate = OpenStaffDateFormatter.date(from: existing.createdAt) ?? Date.distantPast
            let currentDate = OpenStaffDateFormatter.date(from: item.createdAt) ?? Date.distantPast
            if currentDate >= existingDate {
                byTask[item.taskId] = item
            }
        }

        return byTask
    }

    private static func mapKnowledgeDetail(_ item: KnowledgeItemRecord?) -> LearningKnowledgeItemDetail? {
        guard let item else {
            return nil
        }
        return LearningKnowledgeItemDetail(
            knowledgeItemId: item.knowledgeItemId,
            goal: item.goal,
            summary: item.summary,
            contextAppName: item.context.appName,
            contextBundleId: item.context.appBundleId,
            windowTitle: item.context.windowTitle,
            createdAt: OpenStaffDateFormatter.date(from: item.createdAt),
            constraints: item.constraints.map { constraint in
                LearningKnowledgeConstraint(type: constraint.type, description: constraint.description)
            },
            steps: item.steps.map { step in
                LearningKnowledgeStep(
                    stepId: step.stepId,
                    instruction: step.instruction,
                    sourceEventIds: step.sourceEventIds
                )
            }
        )
    }

    private static func listFiles(withExtension pathExtension: String, under root: URL) -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: root.path) else {
            return []
        }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == pathExtension {
            urls.append(fileURL)
        }
        return urls
    }
}

private struct LearningSessionAggregate {
    let sessionId: String
    var startedAt: Date?
    var endedAt: Date?
    var taskIds: Set<String> = []
    var knowledgeTaskIds: Set<String> = []

    mutating func include(task: LearningTaskSummary, hasKnowledgeItem: Bool) {
        taskIds.insert(task.taskId)
        if hasKnowledgeItem {
            knowledgeTaskIds.insert(task.taskId)
        }

        if let taskStartedAt = task.startedAt {
            if let startedAt {
                self.startedAt = min(startedAt, taskStartedAt)
            } else {
                self.startedAt = taskStartedAt
            }
        }

        let taskEndedAt = task.endedAt ?? task.startedAt
        if let taskEndedAt {
            if let endedAt {
                self.endedAt = max(endedAt, taskEndedAt)
            } else {
                self.endedAt = taskEndedAt
            }
        }
    }
}

private struct TaskChunkRecord: Decodable {
    let taskId: String
    let sessionId: String
    let startTimestamp: String
    let endTimestamp: String
    let eventCount: Int
    let boundaryReason: String
    let primaryContext: TaskContextRecord
}

private struct TaskContextRecord: Decodable {
    let appName: String
}

private struct KnowledgeItemRecord: Decodable {
    let knowledgeItemId: String
    let taskId: String
    let sessionId: String
    let goal: String
    let summary: String
    let steps: [KnowledgeStepRecord]
    let context: KnowledgeContextRecord
    let constraints: [KnowledgeConstraintRecord]
    let createdAt: String
}

private struct KnowledgeStepRecord: Decodable {
    let stepId: String
    let instruction: String
    let sourceEventIds: [String]
}

private struct KnowledgeContextRecord: Decodable {
    let appName: String
    let appBundleId: String
    let windowTitle: String?
}

private struct KnowledgeConstraintRecord: Decodable {
    let type: String
    let description: String
}

enum OpenStaffWorkspacePaths {
    static var repositoryRoot: URL {
        let fileManager = FileManager.default
        var candidate = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)

        for _ in 0..<8 {
            let dataPath = candidate.appendingPathComponent("data", isDirectory: true).path
            let docsPath = candidate.appendingPathComponent("docs", isDirectory: true).path
            if fileManager.fileExists(atPath: dataPath),
               fileManager.fileExists(atPath: docsPath) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }

        return URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    }

    static var dataDirectory: URL {
        repositoryRoot.appendingPathComponent("data", isDirectory: true)
    }

    static var logsDirectory: URL {
        dataDirectory.appendingPathComponent("logs", isDirectory: true)
    }

    static var knowledgeDirectory: URL {
        dataDirectory.appendingPathComponent("knowledge", isDirectory: true)
    }

    static var taskChunksDirectory: URL {
        dataDirectory.appendingPathComponent("task-chunks", isDirectory: true)
    }

    static func ensureDataDirectoryWritable() -> Bool {
        let fileManager = FileManager.default
        let dataPath = dataDirectory.path

        do {
            try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        } catch {
            return false
        }

        return fileManager.isWritableFile(atPath: dataPath)
    }
}

enum OpenStaffDateFormatter {
    static func displayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    static func date(from value: String) -> Date? {
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let fractionalDate = formatterWithFractional.date(from: value) {
            return fractionalDate
        }
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        return formatterWithoutFractional.date(from: value)
    }
}

private extension OpenStaffMode {
    var color: Color {
        switch self {
        case .teaching:
            return .blue
        case .assist:
            return .orange
        case .student:
            return .green
        }
    }
}
