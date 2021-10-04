// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnawaitedFuturesTest);
  });
}

@reflectiveTest
class UnawaitedFuturesTest extends LintRuleTest {
  @override
  String get lintRule => 'unawaited_futures';

  test_undefinedIdentifier() async {
    await assertDiagnostics(r'''
f() async {
  Duration d = Duration();
  Future.delayed(d, bar);
}
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 59, 3),
    ]);
  }
}
