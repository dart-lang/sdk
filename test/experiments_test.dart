// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'rule_test.dart';
import 'rules/experiments/experiments.dart';

void main() {
  group('experiments', () {
    registerLintRuleExperiments();

    for (var entry in Directory(p.join(ruleDir, 'experiments')).listSync()) {
      if (entry is! Directory) continue;

      group(p.basename(entry.path), () {
        final analysisOptionsFile =
            File(p.join(entry.path, 'analysis_options.yaml'));
        final analysisOptions = analysisOptionsFile.readAsStringSync();
        final ruleTestDir = Directory(p.join(entry.path, 'rules'));
        for (var test in ruleTestDir.listSync()) {
          if (test is! File) continue;
          final testFile = test as File;
          final ruleName = p.basenameWithoutExtension(test.path);
          testRule(ruleName, testFile,
              analysisOptions: analysisOptions, debug: true);
        }
      });
    }
  });
}
