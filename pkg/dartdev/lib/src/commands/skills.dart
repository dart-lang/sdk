// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../core.dart';

const _skillsRepo = 'dart-lang/skills';
const _rawBase = 'https://raw.githubusercontent.com/$_skillsRepo/main';
const _manifestUrl = '$_rawBase/resources/dart_skills.yaml';

// Maps an agent id to the relative directory (within a project) where its
// skills are stored.
const Map<String, String> _agentSkillDirs = {
  'claude-code': '.claude/skills',
  'cursor': '.cursor/rules',
  'gemini-cli': '.gemini/skills',
  'universal': '.agents/skills',
};

class SkillsCommand extends DartdevCommand {
  static const String cmdName = 'skills';

  static const String cmdDescription =
      '''Manage agent skills for Dart development.

Agent skills are AI coding assistant instructions from
https://github.com/dart-lang/skills that teach agents Dart-specific workflows
such as writing tests, running static analysis, or resolving package conflicts.

By default, skills are installed into the current project root directory under the
agent's configuration folder (e.g. .claude/skills/, .agents/skills/). Use
--global (-g) to install for the current user across all projects instead.

Available subcommands:
  list              List all available skills.
  find <keyword>    Find skills matching a keyword.
  install <skill>   Install a skill (use --all to install all skills).
  remove <skill>    Remove an installed skill.

Examples:
  dart skills list
  dart skills find test
  dart skills install dart-add-unit-test
  dart skills install dart-add-unit-test --global
  dart skills install --all
  dart skills install dart-add-unit-test --agent=claude-code,cursor
  dart skills remove dart-add-unit-test
  dart skills remove dart-add-unit-test --global''';

  SkillsCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose) {
    addSubcommand(_ListCommand(verbose: verbose));
    addSubcommand(_FindCommand(verbose: verbose));
    addSubcommand(_InstallCommand(verbose: verbose));
    addSubcommand(_RemoveCommand(verbose: verbose));
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;
}

class _SkillInfo {
  final String name;
  final String description;
  final String examplePrompt;

  const _SkillInfo({
    required this.name,
    required this.description,
    required this.examplePrompt,
  });
}

Future<List<_SkillInfo>> _fetchSkills(http.Client client) async {
  final response = await client.get(Uri.parse(_manifestUrl));
  if (response.statusCode != 200) {
    throw Exception(
      'Failed to fetch skill list (HTTP ${response.statusCode}).',
    );
  }
  final yaml = loadYaml(response.body);
  final skills = <_SkillInfo>[];
  for (final entry in yaml as YamlList) {
    final m = entry as YamlMap;
    skills.add(
      _SkillInfo(
        name: m['name'] as String,
        description: m['description'] as String,
        examplePrompt: (m['examplePrompt'] as String?) ?? '',
      ),
    );
  }
  return skills;
}

Future<String> _fetchSkillContent(http.Client client, String name) async {
  final url = '$_rawBase/skills/$name/SKILL.md';
  final response = await client.get(Uri.parse(url));
  if (response.statusCode == 404) {
    throw Exception("Skill '$name' not found at $url.");
  }
  if (response.statusCode != 200) {
    throw Exception(
      "Failed to fetch skill '$name' (HTTP ${response.statusCode}).",
    );
  }
  return response.body;
}

List<String> _detectAgents(String projectDir) {
  final home = Platform.environment['HOME'] ?? '';
  final detected = <String>[];

  if (Directory(path.join(projectDir, '.claude')).existsSync() ||
      Directory(path.join(home, '.claude')).existsSync()) {
    detected.add('claude-code');
  }
  if (Directory(path.join(projectDir, '.cursor')).existsSync()) {
    detected.add('cursor');
  }
  if (Directory(path.join(projectDir, '.gemini')).existsSync()) {
    detected.add('gemini-cli');
  }

  return detected.isEmpty ? ['universal'] : detected;
}

String _homeDir() =>
    Platform.environment['HOME'] ??
    Platform.environment['USERPROFILE'] ??
    Directory.current.path;

String _projectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(path.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
}

String _baseDir({required bool global}) =>
    global ? _homeDir() : _projectRoot();

Directory _skillDir(String baseDir, String agent, String skillName) {
  return Directory(path.join(baseDir, _agentSkillDirs[agent]!, skillName));
}

class _ListCommand extends DartdevCommand {
  static const String cmdName = 'list';

  static const String cmdDescription = 'List available skills.';

  _ListCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose);

  @override
  FutureOr<int> run() async {
    final client = http.Client();
    try {
      final skills = await _fetchSkills(client);
      for (final skill in skills) {
        print(skill.name);
        print('  ${skill.description}');
        print('');
      }
      return 0;
    } on Exception catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    } finally {
      client.close();
    }
  }
}

class _FindCommand extends DartdevCommand {
  static const String cmdName = 'find';

  static const String cmdDescription = 'Find skills by keyword.';

  _FindCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose);

  @override
  String get invocation => '${super.invocation} <keyword>';

  @override
  FutureOr<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException('A keyword argument is required.');
    }
    final keyword = rest.first.toLowerCase();

    final client = http.Client();
    try {
      final skills = await _fetchSkills(client);
      final matches =
          skills
              .where(
                (s) =>
                    s.name.toLowerCase().contains(keyword) ||
                    s.description.toLowerCase().contains(keyword),
              )
              .toList();

      if (matches.isEmpty) {
        print("No skills found matching '$keyword'.");
        return 0;
      }
      for (final skill in matches) {
        print(skill.name);
        print('  ${skill.description}');
        if (skill.examplePrompt.isNotEmpty) {
          print('  Example: ${skill.examplePrompt}');
        }
        print('');
      }
      return 0;
    } on Exception catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    } finally {
      client.close();
    }
  }
}

class _InstallCommand extends DartdevCommand {
  static const String cmdName = 'install';

  static const String cmdDescription = 'Install a skill.';

  _InstallCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose) {
    argParser
      ..addFlag(
        'all',
        help: 'Install all available skills.',
        negatable: false,
      )
      ..addOption(
        'agent',
        help:
            'Comma-separated list of agents to install the skill for. '
            'Defaults to all detected agents.\n'
            'Supported: ${_agentSkillDirs.keys.join(', ')}.',
        valueHelp: 'AGENT',
      )
      ..addFlag(
        'global',
        abbr: 'g',
        help: 'Install the skill globally for the current user '
            'rather than for the current project.',
        negatable: false,
      );
  }

  @override
  String get invocation => '${super.invocation} [<skill>]';

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final installAll = args.flag('all');
    final agentOpt = args.option('agent');
    final global = args.flag('global');
    final rest = args.rest;

    if (!installAll && rest.isEmpty) {
      usageException('Provide a skill name or use --all.');
    }
    if (installAll && rest.isNotEmpty) {
      usageException('Cannot specify a skill name together with --all.');
    }

    final requestedAgents = agentOpt != null
        ? agentOpt.split(',').map((s) => s.trim()).toList()
        : <String>[];
    final unknownAgents =
        requestedAgents.where((a) => !_agentSkillDirs.containsKey(a)).toList();
    if (unknownAgents.isNotEmpty) {
      usageException(
        "Unknown agent(s): ${unknownAgents.join(', ')}. "
        'Supported: ${_agentSkillDirs.keys.join(', ')}.',
      );
    }
    final baseDir = _baseDir(global: global);
    final agents = requestedAgents.isEmpty
        ? _detectAgents(baseDir)
        : requestedAgents;

    final client = http.Client();
    try {
      final availableSkills = await _fetchSkills(client);
      final availableNames = {for (final s in availableSkills) s.name};

      final skillNames = installAll ? availableNames.toList() : rest;

      for (final name in skillNames) {
        if (!availableNames.contains(name)) {
          stderr.writeln(
            "Skill '$name' not found. "
            "Run 'dart skills list' to see available skills.",
          );
          return 1;
        }
      }

      for (final name in skillNames) {
        final content = await _fetchSkillContent(client, name);
        for (final agent in agents) {
          final dir = _skillDir(baseDir, agent, name);
          dir.createSync(recursive: true);
          File(path.join(dir.path, 'SKILL.md')).writeAsStringSync(content);
          print("Installed '$name' for $agent.");
        }
      }
      return 0;
    } on Exception catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    } finally {
      client.close();
    }
  }
}

class _RemoveCommand extends DartdevCommand {
  static const String cmdName = 'remove';

  static const String cmdDescription = 'Remove a skill.';

  _RemoveCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose) {
    argParser
      ..addOption(
        'agent',
        help:
            'Comma-separated list of agents to remove the skill from. '
            'Defaults to all detected agents.\n'
            'Supported: ${_agentSkillDirs.keys.join(', ')}.',
        valueHelp: 'AGENT',
      )
      ..addFlag(
        'global',
        abbr: 'g',
        help: 'Remove the skill from the global user installation '
            'rather than from the current project.',
        negatable: false,
      );
  }

  @override
  String get invocation => '${super.invocation} <skill>';

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final agentOpt = args.option('agent');
    final global = args.flag('global');

    if (args.rest.isEmpty) {
      usageException('A skill name is required.');
    }
    final name = args.rest.first;

    final requestedAgents = agentOpt != null
        ? agentOpt.split(',').map((s) => s.trim()).toList()
        : <String>[];
    final unknownAgents =
        requestedAgents.where((a) => !_agentSkillDirs.containsKey(a)).toList();
    if (unknownAgents.isNotEmpty) {
      usageException(
        "Unknown agent(s): ${unknownAgents.join(', ')}. "
        'Supported: ${_agentSkillDirs.keys.join(', ')}.',
      );
    }
    final baseDir = _baseDir(global: global);
    final agents = requestedAgents.isEmpty
        ? _detectAgents(baseDir)
        : requestedAgents;

    var removed = false;
    for (final agent in agents) {
      final dir = _skillDir(baseDir, agent, name);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        print("Removed '$name' for $agent.");
        removed = true;
      }
    }

    if (!removed) {
      stderr.writeln(
        "Skill '$name' was not found for the specified agent(s).",
      );
      return 1;
    }
    return 0;
  }
}
