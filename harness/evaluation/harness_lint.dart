#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

const _requiredFiles = <String>[
  'AGENTS.md',
  'README.md',
  'docs/agent/project-map.md',
  'docs/agent/execution-harness.md',
  'docs/agent/update-rules.md',
  'docs/agent/design-principles.md',
  'docs/agent/adoption.md',
  'docs/agent/plans/README.md',
  'docs/agent/plans/_template.md',
  'harness/map/project_map.json',
  'harness/evaluation/checks.json',
  'harness/evaluation/eval.sh',
];

final _errors = <String>[];

void main() {
  _checkRequiredFiles();
  final map = _readObject('harness/map/project_map.json');
  final checks = _readObject('harness/evaluation/checks.json');

  if (map != null) _checkProjectMap(map);
  if (checks != null) _checkEvaluationConfig(checks);
  _checkMarkdownLinks();

  if (_errors.isNotEmpty) {
    stderr.writeln('Harness lint failed with ${_errors.length} issue(s):');
    for (final error in _errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Harness lint passed: structure, maps, checks, and links are valid.',
  );
}

void _checkRequiredFiles() {
  for (final path in _requiredFiles) {
    if (!File(path).existsSync()) {
      _errors.add('Missing required file: $path');
    }
  }
}

Map<String, dynamic>? _readObject(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, dynamic>) return decoded;
    _errors.add('$path: root must be a JSON object.');
  } on FormatException catch (error) {
    _errors.add('$path: invalid JSON (${error.message}).');
  }
  return null;
}

void _checkProjectMap(Map<String, dynamic> map) {
  if (map['schema_version'] != 1) {
    _errors.add('project_map.json: unsupported schema_version; expected 1.');
  }

  final rawModules = map['modules'];
  if (rawModules is! Map<String, dynamic> || rawModules.isEmpty) {
    _errors.add('project_map.json: "modules" must be a non-empty object.');
    return;
  }

  final names = rawModules.keys.toSet();
  final graph = <String, List<String>>{};

  for (final entry in rawModules.entries) {
    final name = entry.key;
    final rawModule = entry.value;
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      _errors.add('project_map.json: invalid module name "$name".');
    }
    if (rawModule is! Map<String, dynamic>) {
      _errors.add('project_map.json: module "$name" must be an object.');
      continue;
    }

    final path = rawModule['path'];
    if (path is! String || path.trim().isEmpty) {
      _errors.add('project_map.json: module "$name" needs a non-empty path.');
    } else if (!_entityExists(path)) {
      _errors.add(
        'project_map.json: module "$name" path does not exist: $path',
      );
    }

    final entryFiles = _stringList(rawModule['entry_files']);
    if (entryFiles.isEmpty) {
      _errors.add('project_map.json: module "$name" needs entry_files.');
    }
    for (final entryFile in entryFiles) {
      if (!File(entryFile).existsSync()) {
        _errors.add(
          'project_map.json: module "$name" entry file does not exist: $entryFile',
        );
      }
    }

    final signals = _stringList(rawModule['signals']);
    if (signals.isEmpty) {
      _errors.add('project_map.json: module "$name" needs navigation signals.');
    } else if (_normalizedDuplicates(signals).isNotEmpty) {
      _errors.add(
        'project_map.json: module "$name" has duplicate signals: '
        '${_normalizedDuplicates(signals).join(', ')}',
      );
    }

    final dependencies = _stringList(rawModule['depends_on']);
    graph[name] = dependencies;
    for (final dependency in dependencies) {
      if (dependency == name) {
        _errors.add('project_map.json: module "$name" depends on itself.');
      } else if (!names.contains(dependency)) {
        _errors.add(
          'project_map.json: module "$name" references unknown dependency '
          '"$dependency".',
        );
      }
    }
  }

  _checkDependencyCycles(graph);
}

void _checkDependencyCycles(Map<String, List<String>> graph) {
  final visiting = <String>{};
  final visited = <String>{};

  bool visit(String node, List<String> trail) {
    if (visiting.contains(node)) {
      final start = trail.indexOf(node);
      final cycle = [...trail.sublist(start), node];
      _errors.add('project_map.json: dependency cycle: ${cycle.join(' -> ')}');
      return true;
    }
    if (visited.contains(node)) return false;

    visiting.add(node);
    for (final dependency in graph[node] ?? const <String>[]) {
      if (graph.containsKey(dependency) &&
          visit(dependency, [...trail, node])) {
        return true;
      }
    }
    visiting.remove(node);
    visited.add(node);
    return false;
  }

  for (final node in graph.keys) {
    if (visit(node, const [])) return;
  }
}

void _checkEvaluationConfig(Map<String, dynamic> config) {
  if (config['schema_version'] != 1) {
    _errors.add('checks.json: unsupported schema_version; expected 1.');
  }

  final rawChecks = config['checks'];
  if (rawChecks is! List || rawChecks.isEmpty) {
    _errors.add('checks.json: "checks" must be a non-empty array.');
    return;
  }

  final ids = <String>{};
  const validModes = {'quick', 'full'};
  for (var index = 0; index < rawChecks.length; index++) {
    final rawCheck = rawChecks[index];
    if (rawCheck is! Map<String, dynamic>) {
      _errors.add('checks.json: check at index $index must be an object.');
      continue;
    }
    final id = rawCheck['id'];
    if (id is! String || !RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id)) {
      _errors.add('checks.json: check at index $index has an invalid id.');
    } else if (!ids.add(id)) {
      _errors.add('checks.json: duplicate check id "$id".');
    }

    final command = rawCheck['command'];
    if (command is! String || command.trim().isEmpty) {
      _errors.add('checks.json: check "$id" needs a non-empty command.');
    }

    final modes = _stringList(rawCheck['modes']);
    if (modes.isEmpty || modes.any((mode) => !validModes.contains(mode))) {
      _errors.add(
        'checks.json: check "$id" modes must use only quick and full.',
      );
    }
  }
}

void _checkMarkdownLinks() {
  final linkPattern = RegExp(r'\[[^\]]*\]\(([^)]+)\)');
  for (final file in _documentationFiles()) {
    final path = file.path;
    final content = file.readAsStringSync();
    for (final match in linkPattern.allMatches(content)) {
      var target = match.group(1)!.trim();
      if (target.startsWith('<') && target.endsWith('>')) {
        target = target.substring(1, target.length - 1);
      }
      if (target.startsWith('http://') ||
          target.startsWith('https://') ||
          target.startsWith('mailto:') ||
          target.startsWith('#')) {
        continue;
      }
      target = target.split('#').first.split('?').first;
      if (target.isEmpty) continue;
      final resolved = '${file.parent.path}/$target';
      if (!_entityExists(resolved)) {
        _errors.add('$path: local Markdown link does not exist: $target');
      }
    }
  }
}

Iterable<File> _documentationFiles() sync* {
  for (final path in const ['README.md', 'AGENTS.md', 'harness/README.md']) {
    final file = File(path);
    if (file.existsSync()) yield file;
  }

  final docs = Directory('docs');
  if (!docs.existsSync()) return;
  for (final entity in docs.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.md')) yield entity;
  }
}

bool _entityExists(String path) {
  return File(path).existsSync() || Directory(path).existsSync();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

Set<String> _normalizedDuplicates(List<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    final normalized = value.trim().toLowerCase();
    if (!seen.add(normalized)) duplicates.add(normalized);
  }
  return duplicates;
}
