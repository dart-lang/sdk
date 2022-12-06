// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstTest);
  });
}

@reflectiveTest
class UnnecessaryConstTest extends LintRuleTest {
  @override
  List<String> get experiments => ['records'];

  @override
  String get lintRule => 'unnecessary_const';

  test_recordLiteral() async {
    await assertDiagnostics(r'''
const r = const (a: 1);
''', [
      lint(10, 12),
    ]);
  }

  test_recordLiteral_ok() async {
    await assertNoDiagnostics(r'''
const r = (a: 1);
''');
  }
}
