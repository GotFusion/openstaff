# modules/student/

学生模式模块。

## 当前实现（Phase 4.3）
- 已实现最小闭环：任务目标输入 -> 规则自动规划 -> 技能执行（模拟） -> 结构化审阅报告输出。
- 运行入口：`make student ARGS="--goal '在 Safari 中复现点击流程' --knowledge core/knowledge/examples/knowledge-item.sample.json"`

## 后续实现
- 规划策略从规则扩展到模型。
- 执行器从模拟调用升级为 OpenClaw 实际执行。
- 审阅报告加入老师反馈回写与知识纠偏。
