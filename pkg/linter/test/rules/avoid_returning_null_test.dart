// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturningNullTest);
  });
}

@reflectiveTest
class AvoidReturningNullTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_returning_null';

  /// https://github.com/dart-lang/linter/issues/2636
  test_nullableValue() async {
    await assertNoDiagnostics(r'''
 int? getFoo() => null;
''');
  }
}
