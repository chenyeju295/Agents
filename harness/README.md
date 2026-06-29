# Harness 系统说明

Agent 执行系统。让 agent 低 token 理解项目、定向加载上下文、强制通过验证闭环。

---

## 结构

```
harness/
  AGENTS.md              ← Agent 主入口（行为规范 + 决策树）
  map/
    project_map.json     ← 包依赖图（索引单位：package，不是文件）
    flow_index.json      ← 跨包业务流程索引
    api_index.json       ← 公开接口速查表
  runtime/
    context_loader.dart  ← 关键词匹配 + 依赖图展开，输出最小上下文
  evaluation/
    eval.sh              ← analyze → test → build 三关验证闭环
  evolution/
    rules.json           ← 已知错误 → 修复方案（人工维护）
    failure_log.jsonl    ← 失败记录存档
  logs/
    runs/                ← eval 运行日志
  skills/
    native-to-flutter-bridge/  ← 原生封装 Skill（按需加载）
```

---

## 工作流

```
收到任务
  ↓
dart run harness/runtime/context_loader.dart "<task>"
  ↓
输出：需要读的包列表 + barrel 文件 + 相关 spec
  ↓
Agent 定向读取（不扫描全 repo）
  ↓
按 AGENTS.md Decision tree 判断任务类型
  ↓
写代码（遵守 Hard rules R1-R9）
  ↓
bash harness/evaluation/eval.sh <layer> <package>
  ↓
PASS → 提交
FAIL → 查 rules.json → 修复 → 重新 eval
     → 无已知规则 → 记录 failure_log.jsonl → 人工处理
```

---

## 维护规范

| 文件 | 何时更新 |
|------|---------|
| `map/project_map.json` | 新建包、包状态变更、依赖关系变化时 |
| `map/flow_index.json` | 新增跨包业务流程时 |
| `map/api_index.json` | 公开接口签名变更时 |
| `evolution/rules.json` | 人工从 failure_log 提取新规则时 |

**project_map.json 是所有索引的单一真实来源，改包必改 map。**

---

## 设计决策

**为什么索引单位是 package 而不是文件？**  
这是 monorepo 分层架构决定的。每个包有明确边界（barrel），agent 只需要读 barrel 就能理解包的公开接口，不需要读 src/ 内部实现。

**为什么 evolution 不自动写入 rules.json？**  
自动生成的规则缺乏验证，可能引入错误的修复方案。failure_log 是原始记录，rules.json 是经过人工确认的知识库，两者分离保证规则质量。

**为什么 context_loader 用 Dart 写而不是 Python？**  
团队技术栈是 Dart/Flutter，减少工具链依赖。直接 `dart run` 无需额外安装。
