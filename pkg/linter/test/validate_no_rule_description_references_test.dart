// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

void main() {
  group('check for rule message descriptions in tests:', () {
    registerLintRules();
    for (var rule in Analyzer.facade.registeredRules) {
      test(rule.name, () async {
        var result = Process.runSync('grep', ['-R', rule.description, 'test']);
        expect(result.stdout, isEmpty,
            reason:
                'Tests that hardcode descriptions make lint messages hard to evolve.');
      });
    }
  });
}
