import Foundation

// MARK: - Mode Definitions

public enum OpenStaffMode: String, Codable, CaseIterable, Sendable {
    case teaching
    case assist
    case student
}

public enum OrchestratorCapability: String, Codable, CaseIterable, Sendable {
    case observeTeacherActions
    case captureRawEvents
    case sliceTasks
    case buildKnowledgeItems
    case summarizeKnowledge
    case predictNextAction
    case requestTeacherConfirmation
    case executeConfirmedAction
    case planAutonomousTask
    case executeAutonomousTask
    case generateExecutionReport
}

// MARK: - Transition Contracts

public enum ModeTransitionRequirement: String, Codable, CaseIterable, Sendable {
    case teacherConfirmed
    case learnedKnowledgeReady
    case executionPlanReady
    case noPendingAssistSuggestion
    case emergencyStopInactive
}

public struct ModeTransitionContext: Codable, Equatable, Sendable {
    public let traceId: String
    public let sessionId: String
    public let taskId: String?
    public let timestamp: String
    public let teacherConfirmed: Bool
    public let learnedKnowledgeReady: Bool
    public let executionPlanReady: Bool
    public let pendingAssistSuggestion: Bool
    public let emergencyStopActive: Bool

    public init(
        traceId: String,
        sessionId: String,
        taskId: String? = nil,
        timestamp: String,
        teacherConfirmed: Bool = false,
        learnedKnowledgeReady: Bool = false,
        executionPlanReady: Bool = false,
        pendingAssistSuggestion: Bool = false,
        emergencyStopActive: Bool = false
    ) {
        self.traceId = traceId
        self.sessionId = sessionId
        self.taskId = taskId
        self.timestamp = timestamp
        self.teacherConfirmed = teacherConfirmed
        self.learnedKnowledgeReady = learnedKnowledgeReady
        self.executionPlanReady = executionPlanReady
        self.pendingAssistSuggestion = pendingAssistSuggestion
        self.emergencyStopActive = emergencyStopActive
    }
}

public struct ModeTransitionDecision: Codable, Equatable, Sendable {
    public let fromMode: OpenStaffMode
    public let toMode: OpenStaffMode
    public let accepted: Bool
    public let status: OrchestratorStatusCode
    public let errorCode: OrchestratorErrorCode?
    public let unmetRequirements: [ModeTransitionRequirement]
    public let message: String

    public init(
        fromMode: OpenStaffMode,
        toMode: OpenStaffMode,
        accepted: Bool,
        status: OrchestratorStatusCode,
        errorCode: OrchestratorErrorCode? = nil,
        unmetRequirements: [ModeTransitionRequirement] = [],
        message: String
    ) {
        self.fromMode = fromMode
        self.toMode = toMode
        self.accepted = accepted
        self.status = status
        self.errorCode = errorCode
        self.unmetRequirements = unmetRequirements
        self.message = message
    }
}

// MARK: - Log Contract

public struct OrchestratorLogEntry: Codable, Equatable, Sendable {
    public let timestamp: String
    public let traceId: String
    public let sessionId: String
    public let taskId: String?
    public let component: String
    public let status: String
    public let errorCode: String?
    public let message: String
    public let fromMode: OpenStaffMode
    public let toMode: OpenStaffMode
    public let unmetRequirements: [ModeTransitionRequirement]

    public init(
        timestamp: String,
        traceId: String,
        sessionId: String,
        taskId: String?,
        component: String = "orchestrator.mode-state-machine",
        status: String,
        errorCode: String? = nil,
        message: String,
        fromMode: OpenStaffMode,
        toMode: OpenStaffMode,
        unmetRequirements: [ModeTransitionRequirement] = []
    ) {
        self.timestamp = timestamp
        self.traceId = traceId
        self.sessionId = sessionId
        self.taskId = taskId
        self.component = component
        self.status = status
        self.errorCode = errorCode
        self.message = message
        self.fromMode = fromMode
        self.toMode = toMode
        self.unmetRequirements = unmetRequirements
    }
}

// MARK: - Error / Status Catalog

public enum OrchestratorErrorCode: String, Codable, Sendable {
    case transitionDenied = "ORC-STATE-TRANSITION-DENIED"
    case guardConditionFailed = "ORC-STATE-GUARD-FAILED"
}

public enum OrchestratorStatusCode: String, Codable, Sendable {
    case modeStable = "STATUS_ORC_MODE_STABLE"
    case modeTransitionAccepted = "STATUS_ORC_MODE_TRANSITION_ACCEPTED"
    case modeTransitionRejected = "STATUS_ORC_MODE_TRANSITION_REJECTED"
}
