// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';

import 'doc.dart';
import 'since.dart';

/// Generates a list of lint rules in machine format suitable for consumption by
/// other tools.
void main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('pretty',
        abbr: 'p', help: 'Pretty-print output.', defaultsTo: true)
    ..addFlag('sets', abbr: 's', help: 'Include rule sets', defaultsTo: true);
  var options = parser.parse(args);

  registerLintRules();
  if (options['sets'] == true) {
    await fetchBadgeInfo();
  }
  var json = getMachineListing(Registry.ruleRegistry,
      pretty: options['pretty'] == true);
  print(json);
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
        // todo(pq): here for backwards compatibility -- should be removed.
        'maturity': rule.state.label,
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
        if (sinceInfo != null)
          'sinceLinter': sinceInfo[rule.name]?.sinceLinter ?? 'Unreleased',
      }
  ]);
  return json;
}
