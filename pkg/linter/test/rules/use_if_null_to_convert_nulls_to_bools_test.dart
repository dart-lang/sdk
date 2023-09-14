// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIfNullToConvertNullsToBoolsTest);
  });
}

@reflectiveTest
class UseIfNullToConvertNullsToBoolsTest extends LintRuleTest {
  @override
  String get lintRule => 'use_if_null_to_convert_nulls_to_bools';

  test_equalEqual_false() async {
    await assertNoDiagnostics(r'''
bool? e;
bool r = e == false;
''');
  }

  test_equalEqual_true() async {
    await assertDiagnostics(r'''
bool? e;
bool r = e == true;
''', [
      lint(18, 9),
    ]);
  }

  test_notEqual_false() async {
    await assertDiagnostics(r'''
bool? e;
bool r = e != false;
''', [
      lint(18, 10),
    ]);
  }

  test_notEqual_true() async {
    await assertNoDiagnostics(r'''
bool? e;
bool r = e != true;
''');
  }

  test_questionQuestion_false() async {
    await assertNoDiagnostics(r'''
bool? e;
bool r = e ?? false;
''');
  }

  test_questionQuestion_true() async {
    await assertNoDiagnostics(r'''
bool? e;
bool r = e ?? true;
''');
  }
}
