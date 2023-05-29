// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullChecksTest);
  });
}

@reflectiveTest
class UnnecessaryNullChecksTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_null_checks';

  test_completerComplete() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(int? i) => Completer<int>().complete(i!);
''');
  }

  test_futureValue() async {
    await assertNoDiagnostics(r'''
void f(int? i) => Future<int>.value(i!);
''');
  }

  test_listPattern() async {
    await assertDiagnostics(r'''
void f(int? a, int? b) {
  [b!, ] = [a, ];
}
''', [
      lint(29, 1),
    ]);
  }

  test_recordPattern() async {
    await assertDiagnostics(r'''
void f(int? a, int? b) {
  (b!, ) = (a, );
}
''', [
      lint(29, 1),
    ]);
  }

  test_undefinedFunction() async {
    await assertDiagnostics(r'''
f6(int? p) {
  return B() + p!; // OK
}
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 22, 1),
    ]);
  }
}
