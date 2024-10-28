// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultCasesTest);
  });
}

@reflectiveTest
class NoDefaultCasesTest extends LintRuleTest {
  @override
  String get lintRule => 'no_default_cases';

  test_enumLikeType() async {
    await assertDiagnostics(r'''
class C {
  final int i;
  const C._(this.i);

  static const a = C._(1);
  static const b = C._(2);
  static const c = C._(3);
}

void f(C c) {
  switch (c) {
    case C.a :
      print('a');
      break;
    default:
      print('default');
  }
}
''', [
      lint(210, 32),
    ]);
  }

  test_enumType() async {
    await assertDiagnostics(r'''
void f(E e) {
  switch(e) {
    case E.a :
      print('a');
      break;
    default:
      print('default');
  }
}

enum E {
  a, b, c;
}
''', [
      lint(78, 32),
    ]);
  }

  test_intType() async {
    await assertNoDiagnostics(r'''
void f(int i) {
  switch (i) {
    case 1 :
      print('1');
      break;
    default:
      print('default');
  }
}
''');
  }
}
