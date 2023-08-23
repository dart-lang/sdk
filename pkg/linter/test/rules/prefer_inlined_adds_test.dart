// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferInlinedAddsTest);
  });
}

@reflectiveTest
class PreferInlinedAddsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_inlined_adds';

  test_listLiteral_addAll_nonListLiteral() async {
    await assertNoDiagnostics(r'''
var x;
var y = ['a']..addAll(x ?? const []);
''');
  }

  test_listLiteral_cascadeAdd() async {
    await assertDiagnostics(r'''
var x = ['a']..add('b');
''', [
      lint(15, 3),
    ]);
  }

  test_listLiteral_cascadeAdd_multiple() async {
    await assertDiagnostics(r'''
var x = ['a']..add('b')..add('c');
''', [
      lint(15, 3),
    ]);
  }

  test_listLiteral_cascadeAddAll_listLiteral() async {
    await assertDiagnostics(r'''
var x = ['a']..addAll(['b', 'c']);
''', [
      lint(15, 6),
    ]);
  }
}
