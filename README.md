# Agent Harness Engineering

一套可复制到其他代码仓库的 Agent 开发框架，用工程约束提升 AI 编程的可预测性、最小变更能力和验证质量。

## 当前阶段

Stage 0：固化 Agent 工作协议、项目入口、上下文规则、验证规则和文档更新边界。

仓库只包含 Harness 本身，不包含业务实践示例。任何语言或框架相关规则都应由接入项目自行补充，而不是写入通用内核。

## 核心入口

| 文件 | 作用 |
|---|---|
| `AGENTS.md` | Agent 的强制工作入口与总规则 |
| `docs/agent/project-map.md` | 当前仓库的真实项目地图 |
| `docs/agent/execution-harness.md` | 任务、上下文、编辑、验证和失败协议 |
| `docs/agent/update-rules.md` | Agent 文档的更新边界 |
| `docs/agent/plans/` | 复杂任务的可恢复执行计划与决策记录 |
| `harness/map/project_map.json` | 供工具读取的结构化项目地图 |
| `harness/runtime/context_loader.dart` | 根据任务描述生成候选上下文 |
| `harness/evaluation/eval.sh` | 执行可配置的验证清单 |
| `harness/evaluation/harness_lint.dart` | 检查地图、配置、依赖和文档完整性 |

## 使用方式

1. 将 `AGENTS.md`、`docs/agent/` 和 `harness/` 复制到目标仓库。
2. 用目标仓库的真实结构更新两份 project map。
3. 在 `harness/evaluation/checks.json` 中配置真实、可执行的验证命令。
4. 删除不适用于目标仓库的规则，补充必要的技术栈约束。
5. 让 Agent 从 `AGENTS.md` 开始每一次任务。

接入和覆盖规则见 `docs/agent/adoption.md`；跨模块、迁移或需要跨会话恢复的工作使用 `docs/agent/plans/`。

```bash
dart run harness/runtime/context_loader.dart "修改验证规则"
bash harness/evaluation/eval.sh quick
```

结构化地图是自动化输入，Markdown 地图是人和 Agent 的导航入口；两者必须描述同一个真实仓库。
