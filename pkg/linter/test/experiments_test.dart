// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_data/rules/experiments/experiments.dart';
import 'rule_test.dart';
import 'test_constants.dart';

void main() {
  group('experiments', () {
    registerLintRuleExperiments();

    for (var entry
        in Directory(p.join(ruleTestDataDir, 'experiments')).listSync()) {
      if (entry is! Directory) continue;

      group(p.basename(entry.path), () {
        var analysisOptionsFile =
            File(p.join(entry.path, 'analysis_options.yaml'));
        var analysisOptions = analysisOptionsFile.readAsStringSync();
        var ruleTestDir = Directory(p.join(entry.path, 'rules'));
        for (var test in ruleTestDir.listSync()) {
          if (test is! File) continue;
          var testFile = test;
          var ruleName = p.basenameWithoutExtension(test.path);
          if (ruleName.startsWith('.')) continue;
          testRule(ruleName, testFile, analysisOptions: analysisOptions);
        }
      });
    }
  });
}
