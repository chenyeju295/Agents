#!/usr/bin/env dart
// harness/runtime/context_loader.dart
//
// 用法：dart run harness/runtime/context_loader.dart "<task description>"
//
// 输出：候选包列表（按相关性排序）+ barrel 路径，供 agent 自主决定加载范围
// 注意：输出是候选池，不是强制加载列表。agent 根据任务复杂度自主选择。

import 'dart:convert';
import 'dart:io';

const _mapPath = 'harness/map/project_map.json';
const _maxDepth = 2;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run harness/runtime/context_loader.dart "<task>"');
    exit(1);
  }

  final task = args.join(' ').toLowerCase();
  final map = _loadJson(_mapPath);
  final packages = map['packages'] as Map<String, dynamic>;

  // Step 1: signals 语义匹配 —— 比包名匹配覆盖更广
  final scored = <String, int>{};
  for (final entry in packages.entries) {
    final name = entry.key;
    final meta = entry.value as Map<String, dynamic>;
    final signals = (meta['signals'] as List?)?.cast<String>() ?? [];

    var score = 0;
    for (final signal in signals) {
      if (task.contains(signal.toLowerCase())) score++;
    }
    // 包名本身也作为信号（向后兼容）
    if (task.contains(name.toLowerCase())) score += 2;

    if (score > 0) scored[name] = score;
  }

  // Step 2: 按分数排序候选包
  final candidates = scored.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Step 3: 沿 depends_on 展开（供 agent 参考，不强制加载）
  final directMatches = candidates.map((e) => e.key).toSet();
  final expanded = <String, int>{}; // packageName → depth
  final frontier = Queue<MapEntry<String, int>>();
  for (final c in directMatches) {
    frontier.add(MapEntry(c, 0));
    expanded[c] = 0;
  }

  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    if (current.value >= _maxDepth) continue;
    final pkg = packages[current.key] as Map<String, dynamic>?;
    final deps = (pkg?['depends_on'] as List?)?.cast<String>() ?? [];
    for (final dep in deps) {
      if (!expanded.containsKey(dep)) {
        expanded[dep] = current.value + 1;
        frontier.add(MapEntry(dep, current.value + 1));
      }
    }
  }

  // Step 4: 构建输出
  final candidateDetails = candidates.map((e) {
    final pkg = packages[e.key] as Map<String, dynamic>;
    return {
      'package': e.key,
      'score': e.value,
      'barrel': '${pkg['path']}${pkg['barrel']}',
      'layer': pkg['layer'],
      'status': pkg['status'],
      'providers': pkg['providers'] ?? [],
      'spec': pkg['spec'],
    };
  }).toList();

  final dependencyContext = expanded.entries
      .where((e) => !directMatches.contains(e.key))
      .map((e) {
        final pkg = packages[e.key] as Map<String, dynamic>?;
        return {
          'package': e.key,
          'depth': e.value,
          'barrel': pkg != null ? '${pkg['path']}${pkg['barrel']}' : null,
          'reason': 'depends_on of matched package',
        };
      }).toList();

  final output = {
    'task': task,
    'candidates': candidateDetails,           // 直接命中，按 score 排序
    'dependency_context': dependencyContext,  // 依赖展开，供参考
    'agent_note': [
      'candidates 是候选池，不是强制加载列表',
      '根据任务复杂度自主选择加载范围',
      '候选不足以解释问题时，允许加载 dependency_context 或扩展',
    ],
    'cross_package': candidateDetails.length > 1,
  };

  stdout.writeln(JsonEncoder.withIndent('  ').convert(output));

  stderr.writeln('\n=== Context Loader (v1.1) ===');
  stderr.writeln('Task      : $task');
  stderr.writeln('Candidates: ${candidates.map((e) => '${e.key}(${e.value})').join(', ')}');
  stderr.writeln('Dep ctx   : ${dependencyContext.map((e) => e['package']).join(', ')}');
  if (candidateDetails.length > 1) {
    stderr.writeln('Tip       : 多包命中 — 考虑读 flow_index.json 确认跨包流程');
  }
  if (candidateDetails.isEmpty) {
    stderr.writeln('Warning   : 无候选包命中 — 检查任务描述或手动指定包名');
  }
}

Map<String, dynamic> _loadJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: $path not found. Run from repo root.');
    exit(1);
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

class Queue<T> {
  final _list = <T>[];
  void add(T item) => _list.add(item);
  T removeFirst() => _list.removeAt(0);
  bool get isNotEmpty => _list.isNotEmpty;
}
