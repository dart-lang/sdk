// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'messages_info.dart';
import 'util/path_utils.dart';

/// Generates a list of built-in lint rules in JSON suitable for
/// consumption by other tools.
///
/// **Deprecated:** This tool and the resulting generated file in
/// `tool/machine/rules.json` are deprecated and should not be relied on.
void main(List<String> args) async {
  var parser =
      ArgParser()
        ..addFlag('write', abbr: 'w', help: 'Write `rules.json` file.');
  var options = parser.parse(args);

  var json = await generateRulesJson();

  if (options['write'] == true) {
    var outFile = machineJsonFile();
    printToConsole('Writing to ${outFile.path}');
    outFile.writeAsStringSync(json);
  } else {
    printToConsole(json);
  }
}

Future<String> generateRulesJson() async {
  registerLintRules();
  var fixStatusMap = readFixStatusMap();
  return await getMachineListing(
    Registry.ruleRegistry,
    fixStatusMap: fixStatusMap,
  );
}

Future<String> getMachineListing(
  Iterable<AbstractAnalysisRule> ruleRegistry, {
  Map<String, String> fixStatusMap = const {},
}) async {
  var rulesToDocument = List<AbstractAnalysisRule>.of(
    ruleRegistry,
    growable: false,
  ).where((rule) => !rule.state.isInternal).sortedBy((rule) => rule.name);

  var json = JsonEncoder.withIndent('  ').convert([
    for (var (rule, info) in rulesToDocument.map(
      (rule) => (rule, messagesRuleInfo[rule.name]!),
    ))
      {
        'name': rule.name,
        'description': rule.description,
        'categories': info.categories.toList(growable: false),
        'state': rule.state.label,
        'incompatible': rule.incompatibleRules,
        'sets': const [],
        'fixStatus':
            fixStatusMap[rule.diagnosticCodes.first.uniqueName] ??
            'unregistered',
        'details': info.deprecatedDetails,
        'sinceDartSdk': _versionToString(info.states.first.since),
      },
  ]);
  return json;
}

File machineJsonFile() {
  var outPath = pathRelativeToPackageRoot(['tool', 'machine', 'rules.json']);
  return File(outPath);
}

Map<String, String> readFixStatusMap() {
  var statusFilePath = pathRelativeToPkgDir([
    'analysis_server',
    'lib',
    'src',
    'services',
    'correction',
    'error_fix_status.yaml',
  ]);
  var contents = File(statusFilePath).readAsStringSync();

  var yaml = loadYamlNode(contents) as YamlMap;
  return <String, String>{
    for (var MapEntry(key: String code, :YamlMap value) in yaml.entries)
      if (code.startsWith('LintCode.')) code: value['status'] as String,
  };
}

String _versionToString(Version? version) {
  if (version == null) return '2.0';

  return '${version.major}.${version.minor}';
}
