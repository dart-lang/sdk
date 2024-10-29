// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

void main() {
  group('check for rule message descriptions in tests:',
      // We just need to validate rule message descriptions in one CI bot.
      onPlatform: {'windows': Skip('Windows host may not have "grep" tool')},
      () {
    registerLintRules();
    for (var rule in Registry.ruleRegistry) {
      test(rule.name, () async {
        var result = Process.runSync('grep', ['-R', rule.description, 'test']);
        expect(result.stdout, isEmpty,
            reason:
                'Tests that hardcode descriptions make lint messages hard to evolve.');
      });
    }
  });
}
