// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyStatementsTest);
  });
}

@reflectiveTest
class EmptyStatementsTest extends LintRuleTest {
  @override
  String get lintRule => 'empty_statements';

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_justEmpties() async {
    await assertDiagnostics(r'''
f() {    
  switch(true) {
    case true :
      ;
      ;
      ;
    case false :
      print('');
    }
}    
''', [
      lint(49, 1),
      lint(57, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading() async {
    await assertDiagnostics(r'''
f() {    
  switch(true) {
    case true :
      ;
      print('');
    case false :
      print('');
    }
}    
''', [
      lint(49, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_leading_trailing() async {
    await assertDiagnostics(r'''
f() {    
  switch(true) {
    case true :
      ;
      ;
    case false :
      print('');
    }
}    
''', [
      lint(49, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_only() async {
    await assertNoDiagnostics(r'''
f() {    
  switch(true) {
    case true :
      ;
    case false :
      print('');
    }
}    
''');
  }

  /// https://github.com/dart-lang/linter/issues/4410
  test_switchPatternCase_trailing() async {
    await assertDiagnostics(r'''
f() {    
  switch(true) {
    case true :
      print('');
      ;
    case false :
      print('');
    }
}    
''', [
      lint(66, 1),
    ]);
  }
}
