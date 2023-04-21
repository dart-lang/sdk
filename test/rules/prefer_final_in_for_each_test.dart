// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalInForEachTestLanguage300);
  });
}

@reflectiveTest
class PreferFinalInForEachTestLanguage300 extends LintRuleTest {
  @override
  String get lintRule => 'prefer_final_in_for_each';

  test_int() async {
    await assertDiagnostics(r'''
f() {
  for (var i in [1, 2, 3]) { }
}  
''', [
      lint(17, 1),
    ]);
  }

  test_int_final_ok() async {
    await assertNoDiagnostics(r'''
f() {    
  for (final i in [1, 2, 3]) { }
}
''');
  }

  test_int_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {    
  for (var i in [1, 2, 3]) {
    i += 1;
  }
}
''');
  }

  test_outOfLoopDeclaration_ok() async {
    await assertNoDiagnostics(r'''
f() {    
  int j;
  for (j in [1, 2, 3]) { }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/4290')
  test_record() async {
    await assertDiagnostics(r'''
f() {
  for (var (i, j) in [(1, 2)]) { }
}  
''', [
      lint(13, 3),
    ]);
  }

  test_record_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  for (var (int i, j) in [(1, 2)]) {
    i++;
  }
}  
''');
  }
}
