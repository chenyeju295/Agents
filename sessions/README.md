# Agent Session Archive

本目录保存 Codex、DeepSeek (DSH)、Cursor 三个智能体工具的会话文本存档，用于长期留存与检索。数据从本机各工具的默认记录位置导出，导出过程不筛选对话内容，只保留消息文本。

## 统计

| 工具 | 会话数 | 消息数 | 体积 | 时间范围 |
|---|---|---|---|---|
| Codex | 471 | 96,683 | 85.5 MiB | 2026-06-24 ~ 2026-10-20 |
| DeepSeek (DSH) | 165 | 9,851 | 16.5 MiB | 2026-08-14 ~ 2026-10-20 |
| Cursor | 344 | 11,669 | 11.6 MiB | 2026-06-29 ~ 2026-08-03 |
| 合计 | 980 | 108,203 | 113.6 MiB | 2026-06-24 ~ 2026-10-20 |

## 目录结构

```text
sessions/
  codex/<project>/<session_id>.jsonl
  deepseek/<project>/<session_id>.jsonl
  cursor/<project>/<composer_id>.jsonl
  manifest.json
  scripts/export_sessions.py
```

`<project>` 由会话工作目录（cwd）转换而来；Cursor 使用 workspace 目录，无法解析时使用 workspace ID。每个会话一个 JSONL 文件。

## 行格式

第一行为会话元数据：

```json
{"type":"session","tool":"codex","session_id":"...","created_at":"...","cwd":"...","source_file":"..."}
```

之后每行一条消息：

```json
{"type":"message","role":"user","text":"...","timestamp":"..."}
```

`role` 为 `user` 或 `assistant`。DeepSeek 的用户消息额外带 `source_kind` 字段，Cursor 会话元数据额外带 `name`、`workspace_id`、`is_archived`、`is_subagent`。

## 导出策略

- 只导出用户与助手消息的文本。
- 不导出：工具调用、工具结果、reasoning、附件、代码检查点、缓存以及 system/developer 指令。
- 消息文本逐字保存：不改写、不裁剪、不摘要、不压缩（文件为 UTF-8 明文 JSONL，无 gzip）。
- Codex 的 user 消息中包含 Codex 注入的上下文（例如 AGENTS.md instructions、environment context），按原样保留，因为导出不做内容筛选。
- 去重规则：Codex 按 session id 合并 47 个 archived 重复副本；DeepSeek 按 session id 合并 8 个 v3/v4 格式重复文件；Cursor 按 composer 合并头部未列出的孤儿 bubble。
- 跳过无消息的会话：Codex 3 个、DeepSeek 8 个、Cursor 158 个（仅工具调用或空会话）。
- 唯一例外：按仓库管理员授权，`sessions/codex/Users-jace-Documents-newapp/019f3a43-157c-7fa0-bf1a-b559000d6722.jsonl` 第 28 行的火山引擎 AK/SK 两个密钥值已替换为 `***`（GitHub push protection 要求），该行其余文本未改动；`manifest.json` 的 `redactions` 字段记录了本次打码。

## 已知范围限制

- Cursor 的本地聊天库（`state.vscdb`）只覆盖 2026-06-29 ~ 2026-08-03，之后没有再产生含文本的本地会话记录。
- Codex 的 `thread_history_1.sqlite` 与 rollout 内容重叠，导出以 rollout 为准，未重复导出。
- 各工具原始记录中的工具输出、图片、快照不在本存档范围内。

## 重新导出

```bash
python3 sessions/scripts/export_sessions.py            # 全部
python3 sessions/scripts/export_sessions.py cursor     # 只导出 Cursor
```

依赖 `python3` 和 PATH 中的 `zstd`。脚本内常量指向本机默认记录位置，运行后会覆盖本目录并更新 `manifest.json`。

## 注意

- 本仓库为私有仓库。
- 存档包含源码片段与本地绝对路径，请勿公开。