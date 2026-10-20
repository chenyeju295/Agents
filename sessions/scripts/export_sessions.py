#!/usr/bin/env python3
"""Export conversation text from agent session records into this repository.

Sources:
  Codex     ~/.codex/sessions, ~/.codex/archived_sessions (rollout-*.jsonl[.zst])
  DeepSeek  ~/.dsh/sessions/<project>/<session>/session*.jsonl.zstd
  Cursor    ~/Library/Application Support/Cursor/User/globalStorage/state.vscdb

Output (relative to this script's parent directory):
  codex/<project>/<session_id>.jsonl
  deepseek/<project>/<session_id>.jsonl
  cursor/<workspace>/<composer_id>.jsonl
  manifest.json

Only message text is exported. Tool calls, tool results, reasoning blocks,
attachments, checkpoints and caches are not included. Message text itself is
kept verbatim: no rewriting, trimming, summarization or compression.
"""

from __future__ import annotations

import glob
import json
import os
import re
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
OUT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CODEX_DIRS = [os.path.join(HOME, ".codex", "sessions"),
              os.path.join(HOME, ".codex", "archived_sessions")]
DSH_ROOT = os.path.join(HOME, ".dsh", "sessions")
CURSOR_DB = os.path.join(
    HOME, "Library", "Application Support", "Cursor", "User", "globalStorage", "state.vscdb")
CURSOR_WS_ROOT = os.path.join(
    HOME, "Library", "Application Support", "Cursor", "User", "workspaceStorage")


def slug(text: str) -> str:
    text = text.strip()
    text = re.sub(r"[^A-Za-z0-9._-]+", "-", text)
    text = re.sub(r"-{2,}", "-", text).strip("-")
    return text or "unknown"


def project_from_path(path: str | None) -> str:
    if not path:
        return "unknown"
    return slug(path)


def iso(ms):
    if ms is None:
        return None
    try:
        return datetime.fromtimestamp(int(ms) / 1000, tz=timezone.utc).isoformat()
    except (TypeError, ValueError, OSError):
        return None


def write_jsonl(path: str, rows) -> int:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    count = 0
    with open(path, "w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")))
            fh.write("\n")
            count += 1
    return count


def is_compressed(path: str) -> bool:
    return path.endswith(".zst") or path.endswith(".zstd")


def first_event(path: str):
    """Read only the first JSONL event of a rollout file."""
    if is_compressed(path):
        proc = subprocess.Popen(["zstd", "-dc", path], stdout=subprocess.PIPE)
        line = proc.stdout.readline()
        proc.stdout.close()
        proc.terminate()
        proc.wait()
    else:
        with open(path, "rb") as fh:
            line = fh.readline()
    try:
        return json.loads(line)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return None


def iter_lines(path: str):
    if is_compressed(path):
        proc = subprocess.Popen(["zstd", "-dc", path], stdout=subprocess.PIPE)
        stream = proc.stdout
    else:
        stream = open(path, "rb")
    try:
        for raw in stream:
            line = raw.strip()
            if line:
                try:
                    yield json.loads(line)
                except (json.JSONDecodeError, UnicodeDecodeError):
                    continue
    finally:
        try:
            stream.close()
        except Exception:
            pass
        if is_compressed(path):
            proc.wait()


# ---------------------------------------------------------------- Codex

CODEX_TEXT_BLOCKS = {"input_text", "output_text", "text"}


def export_codex():
    files = []
    for root in CODEX_DIRS:
        for dirpath, _dirnames, filenames in os.walk(root):
            for name in filenames:
                if name.startswith("rollout-") and (name.endswith(".jsonl") or name.endswith(".jsonl.zst")):
                    files.append(os.path.join(dirpath, name))
    by_session = {}
    for path in files:
        archived = "archived_sessions" in path
        by_session.setdefault(path, None)
    # Resolve the session id of every rollout from its first event, so duplicate
    # copies (sessions vs archived_sessions) can be resolved before parsing bodies.
    metas = {}
    for path in files:
        event = first_event(path)
        payload = (event or {}).get("payload") or {}
        sid = payload.get("id")
        if sid:
            metas.setdefault(sid, []).append(path)
    stats = {"files": 0, "sessions": 0, "messages": 0, "bytes": 0, "skipped_files": 0,
             "skipped_sessions": 0}
    for sid, paths in metas.items():
        # Prefer the live copy over the archived copy.
        paths.sort(key=lambda p: ("archived_sessions" in p, p))
        chosen = [p for p in paths if "archived_sessions" not in p] or paths[:1]
        messages = []
        meta = {}
        used = set()
        for path in chosen:
            for event in iter_lines(path):
                if event.get("type") == "session_meta":
                    payload = event.get("payload") or {}
                    meta = {
                        "session_id": payload.get("id") or sid,
                        "created_at": payload.get("timestamp"),
                        "cwd": payload.get("cwd"),
                        "runtime_workspace_roots": payload.get("runtime_workspace_roots"),
                        "originator": payload.get("originator"),
                        "cli_version": payload.get("cli_version"),
                    }
                elif event.get("type") == "response_item":
                    payload = event.get("payload") or {}
                    if payload.get("type") != "message":
                        continue
                    role = payload.get("role")
                    if role not in ("user", "assistant"):
                        continue
                    mid = payload.get("id")
                    if mid and mid in used:
                        continue
                    used.add(mid)
                    parts = []
                    for block in payload.get("content") or []:
                        if isinstance(block, dict) and block.get("type") in CODEX_TEXT_BLOCKS:
                            parts.append(block.get("text") or "")
                    text = "\n".join(parts)
                    if not text:
                        continue
                    messages.append({
                        "type": "message",
                        "role": role,
                        "text": text,
                        "timestamp": event.get("timestamp"),
                    })
        if not messages:
            stats["skipped_sessions"] += 1
            continue
        project = project_from_path(meta.get("cwd"))
        out = os.path.join(OUT_ROOT, "codex", project, sid + ".jsonl")
        header = {"type": "session", "tool": "codex", **meta, "source_file": os.path.basename(chosen[0])}
        n = write_jsonl(out, [header] + messages)
        stats["files"] += 1
        stats["sessions"] += 1
        stats["messages"] += n - 1
        stats["bytes"] += os.path.getsize(out)
    return stats


# ---------------------------------------------------------------- DeepSeek (DSH)

def export_deepseek():
    files = glob.glob(os.path.join(DSH_ROOT, "*", "*", "session*.jsonl.zstd"))
    stats = {"files": 0, "sessions": 0, "messages": 0, "bytes": 0, "skipped_sessions": 0,
             "duplicate_files": 0}

    def rank(path):
        name = os.path.basename(path)
        if ".v4." in name:
            return 0
        if ".v3." in name:
            return 1
        return 2

    groups = {}
    for path in files:
        event = first_event(path)
        sid = (event or {}).get("id")
        if not sid:
            sid = os.path.basename(os.path.dirname(path))
        groups.setdefault(sid, []).append(path)
    stats["duplicate_files"] = len(files) - len(groups)
    for sid, paths in sorted(groups.items()):
        paths.sort(key=lambda p: (rank(p), -os.path.getsize(p)))
        path = paths[0]
        meta = {}
        messages = []
        for event in iter_lines(path):
            etype = event.get("type")
            data = event.get("data") or {}
            if etype == "session":
                meta = {
                    "session_id": event.get("id"),
                    "created_at": iso(event.get("createdAt")),
                    "cwd": data.get("cwd") or event.get("cwd"),
                    "agent_preset": data.get("agentPreset") or event.get("agentPreset"),
                }
            elif etype == "user/message":
                text = "\n".join(
                    block.get("text") or ""
                    for block in data.get("content") or []
                    if isinstance(block, dict) and block.get("type") == "text")
                if not text:
                    continue
                messages.append({
                    "type": "message",
                    "role": "user",
                    "text": text,
                    "timestamp": iso(event.get("time")),
                    "source_kind": (data.get("source") or {}).get("kind"),
                })
            elif etype == "assistant/message":
                message = data.get("message") or {}
                text = "\n".join(
                    block.get("text") or ""
                    for block in message.get("content") or []
                    if isinstance(block, dict) and block.get("type") == "text")
                if not text:
                    continue
                messages.append({
                    "type": "message",
                    "role": "assistant",
                    "text": text,
                    "timestamp": iso(event.get("time")),
                })
        if not meta:
            meta = {"session_id": sid, "cwd": None, "created_at": None}
        if not messages:
            stats["skipped_sessions"] += 1
            continue
        sid = meta.get("session_id") or sid
        project = project_from_path(meta.get("cwd"))
        out = os.path.join(OUT_ROOT, "deepseek", project, sid + ".jsonl")
        header = {"type": "session", "tool": "deepseek", **meta, "source_file": os.path.basename(path)}
        n = write_jsonl(out, [header] + messages)
        stats["files"] += 1
        stats["sessions"] += 1
        stats["messages"] += n - 1
        stats["bytes"] += os.path.getsize(out)
    return stats


# ---------------------------------------------------------------- Cursor

def rich_text_plain(value):
    """Flatten Cursor's richText Lexical document (or string) into plain text."""
    if not value:
        return ""
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            return value
    parts = []

    def walk(node):
        if isinstance(node, list):
            for item in node:
                walk(item)
            return
        if not isinstance(node, dict):
            return
        if node.get("type") == "text" and isinstance(node.get("text"), str):
            parts.append(node["text"])
            return
        children = node.get("children")
        if isinstance(children, list):
            before = len(parts)
            walk(children)
            if node.get("type") in ("paragraph", "root", "heading", "listitem") and len(parts) > before:
                parts.append("\n")
        elif isinstance(node.get("root"), dict):
            walk(node["root"])

    walk(value)
    return "".join(parts).strip("\n")


def cursor_workspace_names():
    mapping = {}
    for entry in glob.glob(os.path.join(CURSOR_WS_ROOT, "*")):
        meta_path = os.path.join(entry, "workspace.json")
        if not os.path.isfile(meta_path):
            continue
        try:
            meta = json.load(open(meta_path, encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        folder = meta.get("folder") or meta.get("workspace")
        if folder:
            mapping[os.path.basename(entry)] = folder.replace("file://", "")
    return mapping


def export_cursor():
    con = sqlite3.connect("file:" + CURSOR_DB + "?immutable=1", uri=True)
    headers = {}
    for cid, ws, created, updated, archived, subagent in con.execute(
            "select composerId, workspaceId, createdAt, lastUpdatedAt, isArchived, isSubagent "
            "from composerHeaders"):
        headers[cid] = {"workspaceId": ws, "createdAt": created,
                        "lastUpdatedAt": updated, "isArchived": archived,
                        "isSubagent": subagent}
    composers = {}
    for key, value in con.execute("select key, value from cursorDiskKV where key like 'composerData:%'"):
        try:
            data = json.loads(value)
        except (json.JSONDecodeError, TypeError):
            continue
        cid = data.get("composerId") or key.split(":", 1)[1]
        composers[cid] = {
            "composerId": cid,
            "name": data.get("name"),
            "createdAt": data.get("createdAt"),
            "workspaceId": data.get("workspaceId"),
            "headers": [
                {"bubbleId": entry.get("bubbleId"), "createdAt": entry.get("createdAt")}
                for entry in data.get("fullConversationHeadersOnly") or []
                if isinstance(entry, dict) and entry.get("bubbleId")
            ],
        }
    all_bubbles = {}
    for key, value in con.execute("select key, value from cursorDiskKV where key like 'bubbleId:%'"):
        parts = key.split(":")
        if len(parts) != 3:
            continue
        cid, bid = parts[1], parts[2]
        try:
            data = json.loads(value)
        except (json.JSONDecodeError, TypeError):
            continue
        all_bubbles.setdefault(cid, {})[bid] = {
            "type": data.get("type"),
            "text": data.get("text"),
            "richText": data.get("richText"),
            "createdAt": data.get("createdAt"),
        }
    ws_names = cursor_workspace_names()
    stats = {"files": 0, "sessions": 0, "messages": 0, "bytes": 0,
             "skipped_sessions": 0, "skipped_bubbles": 0}
    for cid in sorted(set(headers) | set(composers)):
        data = composers.get(cid) or {}
        info = headers.get(cid) or {}
        order = [(entry["bubbleId"], entry.get("createdAt"))
                 for entry in data.get("headers") or []]
        composer_bubbles = all_bubbles.get(cid) or {}
        seen_headers = {bid for bid, _created in order}
        for bid, bubble in composer_bubbles.items():
            if bid not in seen_headers:
                order.append((bid, bubble.get("createdAt")))
        order.sort(key=lambda item: (item[1] or "", item[0]))
        messages = []
        seen = set()
        for bid, created in order:
            if bid in seen:
                continue
            seen.add(bid)
            bubble = composer_bubbles.get(bid)
            if not bubble:
                continue
            role = {1: "user", 2: "assistant"}.get(bubble.get("type"))
            if role is None:
                continue
            text = bubble.get("text") or ""
            if not text:
                text = rich_text_plain(bubble.get("richText"))
            if not text:
                stats["skipped_bubbles"] += 1
                continue
            messages.append({
                "type": "message",
                "role": role,
                "text": text,
                "timestamp": created or bubble.get("createdAt"),
            })
        if not messages:
            stats["skipped_sessions"] += 1
            continue
        ws = info.get("workspaceId") or data.get("workspaceId") or "unknown"
        workspace = ws_names.get(ws) or ("workspace-" + slug(ws))
        out = os.path.join(OUT_ROOT, "cursor", project_from_path(workspace), cid + ".jsonl")
        header = {
            "type": "session",
            "tool": "cursor",
            "session_id": cid,
            "name": data.get("name"),
            "created_at": iso(info.get("createdAt") or data.get("createdAt")),
            "cwd": ws_names.get(ws),
            "workspace_id": ws,
            "is_archived": info.get("isArchived"),
            "is_subagent": info.get("isSubagent"),
        }
        n = write_jsonl(out, [header] + messages)
        stats["files"] += 1
        stats["sessions"] += 1
        stats["messages"] += n - 1
        stats["bytes"] += os.path.getsize(out)
    con.close()
    return stats


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else "all"
    manifest_path = os.path.join(OUT_ROOT, "manifest.json")
    manifest = {}
    if os.path.isfile(manifest_path):
        try:
            manifest = json.load(open(manifest_path, encoding="utf-8"))
        except json.JSONDecodeError:
            manifest = {}
    if only in ("all", "codex"):
        manifest["codex"] = export_codex()
        print("codex:", manifest["codex"], file=sys.stderr)
    if only in ("all", "deepseek"):
        manifest["deepseek"] = export_deepseek()
        print("deepseek:", manifest["deepseek"], file=sys.stderr)
    if only in ("all", "cursor"):
        manifest["cursor"] = export_cursor()
        print("cursor:", manifest["cursor"], file=sys.stderr)
    manifest["generated_at"] = datetime.now(timezone.utc).isoformat()
    manifest["format"] = {
        "files": "codex/<project>/<session>.jsonl etc.",
        "line_types": ["session", "message"],
        "message_roles": ["user", "assistant"],
        "text_policy": "verbatim message text; no rewriting, trimming, summary or compression",
        "excluded": ["tool calls", "tool results", "reasoning", "attachments",
                     "checkpoints", "caches", "system/developer instructions"],
    }
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2, sort_keys=True)
        fh.write("\n")
    print("wrote", manifest_path, file=sys.stderr)


if __name__ == "__main__":
    main()