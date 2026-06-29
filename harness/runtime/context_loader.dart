#!/usr/bin/env dart

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

const _defaultMapPath = 'harness/map/project_map.json';

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.task.isEmpty) {
    stderr.writeln(
      'Usage: dart run harness/runtime/context_loader.dart '
      '[--map <path>] [--depth <n>] "<task>"',
    );
    exitCode = 64;
    return;
  }

  final map = _readMap(parsed.mapPath);
  final rawModules = map['modules'];
  if (rawModules is! Map<String, dynamic>) {
    stderr.writeln(
      'ERROR: ${parsed.mapPath} must contain an object named "modules".',
    );
    exitCode = 65;
    return;
  }

  final task = parsed.task.toLowerCase();
  final scored = <_Candidate>[];

  for (final entry in rawModules.entries) {
    if (entry.value is! Map<String, dynamic>) continue;
    final module = entry.value as Map<String, dynamic>;
    final signals = _stringList(module['signals']);
    final name = entry.key;
    var score = _matchScore(task, name);
    for (final signal in signals) {
      score += _matchScore(task, signal);
    }
    if (score > 0) scored.add(_Candidate(name, score, module));
  }

  scored.sort((a, b) {
    final scoreOrder = b.score.compareTo(a.score);
    return scoreOrder != 0 ? scoreOrder : a.name.compareTo(b.name);
  });

  final directNames = scored.map((candidate) => candidate.name).toSet();
  final dependencies = _expandDependencies(
    directNames,
    rawModules,
    parsed.maxDepth,
  );

  final output = <String, Object?>{
    'task': parsed.task,
    'map': parsed.mapPath,
    'candidates': [
      for (final candidate in scored)
        {
          'module': candidate.name,
          'score': candidate.score,
          'path': candidate.data['path'],
          'role': candidate.data['role'],
          'entry_files': _stringList(candidate.data['entry_files']),
        },
    ],
    'dependency_context': [
      for (final dependency in dependencies.entries)
        {
          'module': dependency.key,
          'depth': dependency.value,
          'entry_files': _stringList(
            (rawModules[dependency.key]
                as Map<String, dynamic>?)?['entry_files'],
          ),
        },
    ],
    'note': scored.isEmpty
        ? 'No signal matched. Inspect files explicitly named by the task or update the map with verified signals.'
        : 'Candidates are navigation hints. Confirm important claims against source files.',
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
}

_Arguments _parseArgs(List<String> args) {
  var mapPath = _defaultMapPath;
  var maxDepth = 2;
  final taskParts = <String>[];

  for (var index = 0; index < args.length; index++) {
    switch (args[index]) {
      case '--map':
        if (++index >= args.length) _argumentError('--map requires a path.');
        mapPath = args[index];
      case '--depth':
        if (++index >= args.length)
          _argumentError('--depth requires a number.');
        maxDepth = int.tryParse(args[index]) ?? -1;
        if (maxDepth < 0) _argumentError('--depth must be zero or greater.');
      default:
        taskParts.add(args[index]);
    }
  }

  return _Arguments(mapPath, maxDepth, taskParts.join(' ').trim());
}

Never _argumentError(String message) {
  stderr.writeln('ERROR: $message');
  exit(64);
}

Map<String, dynamic> _readMap(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: map not found: $path');
    exit(66);
  }

  try {
    final value = jsonDecode(file.readAsStringSync());
    if (value is Map<String, dynamic>) return value;
  } on FormatException catch (error) {
    stderr.writeln('ERROR: invalid JSON in $path: ${error.message}');
    exit(65);
  }

  stderr.writeln('ERROR: map root must be a JSON object: $path');
  exit(65);
}

int _matchScore(String task, String rawSignal) {
  final signal = rawSignal.trim().toLowerCase();
  if (signal.isEmpty || !task.contains(signal)) return 0;
  return signal.contains(RegExp(r'\s')) ? 2 : 1;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

Map<String, int> _expandDependencies(
  Set<String> directNames,
  Map<String, dynamic> modules,
  int maxDepth,
) {
  final result = <String, int>{};
  final queue = Queue<MapEntry<String, int>>();
  for (final name in directNames) {
    queue.add(MapEntry(name, 0));
  }

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current.value >= maxDepth) continue;
    final module = modules[current.key];
    if (module is! Map<String, dynamic>) continue;
    for (final dependency in _stringList(module['depends_on'])) {
      if (directNames.contains(dependency) || result.containsKey(dependency))
        continue;
      if (!modules.containsKey(dependency)) {
        stderr.writeln(
          'WARNING: ${current.key} references unknown dependency "$dependency".',
        );
        continue;
      }
      final depth = current.value + 1;
      result[dependency] = depth;
      queue.add(MapEntry(dependency, depth));
    }
  }

  return result;
}

final class _Arguments {
  const _Arguments(this.mapPath, this.maxDepth, this.task);

  final String mapPath;
  final int maxDepth;
  final String task;
}

final class _Candidate {
  const _Candidate(this.name, this.score, this.data);

  final String name;
  final int score;
  final Map<String, dynamic> data;
}
