// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';

/// Generates a list of lint rules in machine format suitable for consumption by
/// other tools.
void main([List<String> args]) {
  var parser = ArgParser()
    ..addFlag('pretty',
        abbr: 'p', help: 'Pretty-print output.', defaultsTo: true);
  var options = parser.parse(args);

  registerLintRules();
  var json = getMachineListing(Registry.ruleRegistry,
      pretty: options['pretty'] == true);
  print(json);
}

String getMachineListing(Iterable<LintRule> ruleRegistry,
    {bool pretty = true}) {
  var rules = List<LintRule>.from(ruleRegistry, growable: false)..sort();
  var encoder = pretty ? JsonEncoder.withIndent('  ') : JsonEncoder();
  var json = encoder.convert([
    for (var rule in rules)
      {
        'name': rule.name,
        'description': rule.description,
        'group': rule.group.name,
        'details': rule.details,
      }
  ]);

  return json;
}
