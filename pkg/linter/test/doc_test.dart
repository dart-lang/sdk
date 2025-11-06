// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

import '../tool/machine.dart';

void main() {
  group('doc generation', () {
    setUp(registerLintRules);
    test('fixStatus (sanity)', () {
      var fixStatusMap = readFixStatusMap();
      // Doc generation reads the fix status map to associate fix status
      // badges with rule documentation.  Here we check one for sanity.
      // If the file moves or format changes, we'd expect this to fail.
      expect(fixStatusMap['LintCode.prefer_single_quotes'], 'hasFix');
    });
  });
}
