// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'rule_test.dart';
import 'test_constants.dart';

void main() {
  group('un-mocked', () {
    // Validate that rule tests produce the expected results when run against
    // an un-mocked SDK.
    for (var entry
        in Directory(p.join(ruleTestDataDir, 'unmocked')).listSync()) {
      if (entry is! File) continue;

      var ruleName = p.basenameWithoutExtension(entry.path);
      testRule(ruleName, entry, useMockSdk: false);
    }
  });
}
