// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';
import 'package:path/path.dart' as path;

import 'doc.dart';
import 'since.dart';

/// Generates a list of lint rules in machine format suitable for consumption by
/// other tools.
void main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('write', abbr: 'w', help: 'Write `rules.json` file.')
    ..addFlag('pretty',
        abbr: 'p', help: 'Pretty-print output.', defaultsTo: true)
    ..addFlag('sets', abbr: 's', help: 'Include rule sets', defaultsTo: true);
  var options = parser.parse(args);

  var json = await generateRulesJson(
      pretty: options['pretty'] == true,
      includeSetInfo: options['sets'] == true);

  if (options['write'] == true) {
    var outPath = path.join('tool', 'machine', 'rules.json');
    printToConsole('Writing to $outPath');
    File(outPath).writeAsStringSync(json);
  } else {
    printToConsole(json);
  }
}

Future<String> generateRulesJson(
    {bool pretty = true, bool includeSetInfo = true}) async {
  registerLintRules();
  if (includeSetInfo) {
    await fetchBadgeInfo();
  }
  var fixStatusMap = await fetchFixStatusMap();
  return getMachineListing(Registry.ruleRegistry,
      fixStatusMap: fixStatusMap, sinceInfo: sinceMap, pretty: pretty);
}

String getMachineListing(Iterable<LintRule> ruleRegistry,
    {Map<String, String>? fixStatusMap,
    bool pretty = true,
    Map<String, SinceInfo>? sinceInfo}) {
  var rules = List<LintRule>.of(ruleRegistry, growable: false)..sort();
  var encoder = pretty ? JsonEncoder.withIndent('  ') : JsonEncoder();
  fixStatusMap ??= {};
  var json = encoder.convert([
    for (var rule in rules)
      {
        'name': rule.name,
        'description': rule.description,
        'group': rule.group.name,
        'state': rule.state.label,
        'incompatible': rule.incompatibleRules,
        'sets': [
          if (coreRules.contains(rule.name)) 'core',
          if (recommendedRules.contains(rule.name)) 'recommended',
          if (flutterRules.contains(rule.name)) 'flutter',
        ],
        'fixStatus': fixStatusMap[rule.name] ?? 'unregistered',
        'details': rule.details,
        if (sinceInfo != null)
          'sinceDartSdk': sinceInfo[rule.name]?.sinceDartSdk ?? 'Unreleased',
      }
  ]);
  return json;
}
