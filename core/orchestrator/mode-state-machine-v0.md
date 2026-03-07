# OpenStaff 模式状态机 v0（Phase 4.1）

## 1. 目标

定义三模式运行时状态机，保证：
- 模式切换可审计（接受/拒绝均有日志）。
- 非法切换被拒绝。
- 每种模式只能调用白名单能力。

实现位置：
- `core/contracts/OrchestratorContracts.swift`
- `core/orchestrator/ModeStateMachine.swift`
- `apps/macos/Sources/OpenStaffOrchestratorCLI/*`

## 2. 状态定义

- `teaching`：教学模式，老师主导，系统学习与沉淀知识。
- `assist`：辅助模式，老师主导，系统预测并经确认后协助执行。
- `student`：学生模式，系统根据知识自主规划并执行任务。

## 3. 合法切换图

- `teaching -> assist`（允许）
- `assist -> teaching`（允许）
- `assist -> student`（允许）
- `student -> assist`（允许）
- `student -> teaching`（允许）

默认拒绝：
- `teaching -> student`（跳级切换）
- `mode -> same mode`
- 任意未定义边

## 4. 切换守卫条件

切换守卫字段来自 `ModeTransitionContext`。

### `teaching -> assist`
- `teacherConfirmed == true`
- `learnedKnowledgeReady == true`
- `emergencyStopActive == false`

### `assist -> student`
- `teacherConfirmed == true`
- `learnedKnowledgeReady == true`
- `executionPlanReady == true`
- `pendingAssistSuggestion == false`
- `emergencyStopActive == false`

### `student -> assist`
- `teacherConfirmed == true`
- `emergencyStopActive == false`

### `assist -> teaching` / `student -> teaching`
- 不要求额外守卫（允许回退到教学模式）

## 5. 能力白名单

### teaching
- `observeTeacherActions`
- `captureRawEvents`
- `sliceTasks`
- `buildKnowledgeItems`
- `summarizeKnowledge`

### assist
- `observeTeacherActions`
- `predictNextAction`
- `requestTeacherConfirmation`
- `executeConfirmedAction`

### student
- `planAutonomousTask`
- `executeAutonomousTask`
- `generateExecutionReport`

## 6. 日志与错误码

每次切换输出 `OrchestratorLogEntry`，至少包含：
- `timestamp`
- `traceId`
- `sessionId`
- `taskId`
- `component`
- `status`
- `errorCode`（失败时）

状态码：
- `STATUS_ORC_MODE_STABLE`
- `STATUS_ORC_MODE_TRANSITION_ACCEPTED`
- `STATUS_ORC_MODE_TRANSITION_REJECTED`

错误码：
- `ORC-STATE-TRANSITION-DENIED`
- `ORC-STATE-GUARD-FAILED`

## 7. CLI 验收

查看能力白名单：

```bash
make orchestrator ARGS="--print-capabilities"
```

合法切换：

```bash
make orchestrator ARGS="--from teaching --to assist --session-id session-20260308-a1 --teacher-confirmed --knowledge-ready"
```

非法切换（预期退出码 2）：

```bash
make orchestrator ARGS="--from teaching --to student --session-id session-20260308-a1 --teacher-confirmed --knowledge-ready --plan-ready"
```
