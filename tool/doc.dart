// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';
import 'package:yaml/yaml.dart';

import 'machine.dart';
import 'since.dart';

/// Generates lint rule docs for publishing to https://dart-lang.github.io/
void main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('out', abbr: 'o', help: 'Specifies output directory.')
    ..addFlag('create-dirs',
        abbr: 'd', help: 'Enables creation of necessary directories.');

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'] as String?;

  var createDirectories = options['create-dirs'] == true;

  await generateDocs(outDir, createDirectories: createDirectories);
}

final coreRules = <String?>[];
final flutterRules = <String?>[];
final recommendedRules = <String?>[];

final Map<String, String> _fixStatusMap = <String, String>{};

Future<void> fetchBadgeInfo() async {
  var core = await fetchConfig(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/core.yaml');
  if (core != null) {
    for (var ruleConfig in core.ruleConfigs) {
      coreRules.add(ruleConfig.name);
    }
  }

  var recommended = await fetchConfig(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/recommended.yaml');
  if (recommended != null) {
    recommendedRules.addAll(coreRules);
    for (var ruleConfig in recommended.ruleConfigs) {
      recommendedRules.add(ruleConfig.name);
    }
  }

  var flutter = await fetchConfig(
      'https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml');
  if (flutter != null) {
    flutterRules.addAll(recommendedRules);
    for (var ruleConfig in flutter.ruleConfigs) {
      flutterRules.add(ruleConfig.name);
    }
  }
}

Future<LintConfig?> fetchConfig(String url) async {
  var client = http.Client();
  printToConsole('loading $url...');
  var req = await client.get(Uri.parse(url));
  return processAnalysisOptionsFile(req.body);
}

Future<Map<String, String>> fetchFixStatusMap() async {
  if (_fixStatusMap.isNotEmpty) return _fixStatusMap;
  var url =
      'https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/analysis_server/lib/src/services/correction/error_fix_status.yaml';
  var client = http.Client();
  printToConsole('loading $url...');
  var req = await client.get(Uri.parse(url));
  var yaml = loadYamlNode(req.body) as YamlMap;
  for (var entry in yaml.entries) {
    var code = entry.key as String;
    if (code.startsWith('LintCode.')) {
      _fixStatusMap[code.substring(9)] =
          (entry.value as YamlMap)['status'] as String;
    }
  }
  return _fixStatusMap;
}

Future<void> generateDocs(String? dir, {bool createDirectories = false}) async {
  var outDir = dir;
  if (outDir != null) {
    var d = Directory(outDir);
    if (createDirectories) {
      d.createSync();
    }

    if (!d.existsSync()) {
      printToConsole("Directory '${d.path}' does not exist");
      return;
    }

    if (!File('$outDir/options').existsSync()) {
      var lintsChildDir = Directory('$outDir/lints');
      if (lintsChildDir.existsSync()) {
        outDir = lintsChildDir.path;
      }
    }

    if (createDirectories) {
      Directory('$outDir/machine').createSync();
    }
  }

  registerLintRules();

  // Generate lint count badge.
  await CountBadger(Registry.ruleRegistry).generate(outDir);

  // Fetch info for lint group/style badge generation.
  await fetchBadgeInfo();

  var fixStatusMap = await fetchFixStatusMap();

  // Generate a machine-readable summary of rules.
  MachineSummaryGenerator(Registry.ruleRegistry, fixStatusMap).generate(outDir);
}

void printUsage(ArgParser parser, [String? error]) {
  var message = 'Generates lint docs.';
  if (error != null) {
    message = error;
  }

  stdout.write('''$message
Usage: doc
${parser.usage}
''');
}

class CountBadger {
  Iterable<LintRule> rules;

  CountBadger(this.rules);

  Future<void> generate(String? dirPath) async {
    var lintCount = rules.length;

    var client = http.Client();
    var req = await client.get(
        Uri.parse('https://img.shields.io/badge/lints-$lintCount-blue.svg'));
    var bytes = req.bodyBytes;
    await File('$dirPath/count-badge.svg').writeAsBytes(bytes);
  }
}

class MachineSummaryGenerator {
  final Iterable<LintRule> rules;
  final Map<String, String> fixStatusMap;

  MachineSummaryGenerator(this.rules, this.fixStatusMap);

  void generate(String? filePath) {
    var generated = getMachineListing(rules,
        fixStatusMap: fixStatusMap, sinceInfo: sinceMap);
    if (filePath != null) {
      var outPath = '$filePath/machine/rules.json';
      printToConsole('Writing to $outPath');
      File(outPath).writeAsStringSync(generated);
    } else {
      printToConsole(generated);
    }
  }
}
