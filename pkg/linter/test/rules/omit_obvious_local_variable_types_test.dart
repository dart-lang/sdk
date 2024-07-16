// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OmitObviousLocalVariableTypesTest);
  });
}

@reflectiveTest
class OmitObviousLocalVariableTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'omit_obvious_local_variable_types';

  test_cascade() async {
    await assertDiagnostics(r'''
f() {
  A a = A()..x..x..x;
}

class A {
  final x = 0;
}
''', [
      lint(8, 1),
    ]);
  }

  test_forEach_inferredList() async {
    await assertDiagnostics(r'''
f() {
  for (int i in [1, 2, 3]) { }
}
''', [
      lint(13, 3),
    ]);
  }

  test_forEach_listWithNonObviousElement() async {
    await assertDiagnostics(r'''
f() {
  var j = "Hello".length;
  for (int i in [j, 1, j + 1]) { }
}
''', [
      lint(39, 3),
    ]);
  }

  test_forEach_noDeclaredType() async {
    await assertNoDiagnostics(r'''
f() {
  for (var i in [1, 2, 3]) { }
}
''');
  }

  test_forEach_nonObviousIterable() async {
    await assertNoDiagnostics(r'''
f() {
  var list = [1, 2, 3];
  for (int i in list) { }
}
''');
  }

  test_forEach_typedList() async {
    await assertDiagnostics(r'''
f() {
  for (int i in <int>[1, 2, 3]) { }
}
''', [
      lint(13, 3),
    ]);
  }

  test_genericInvocation_paramIsType() async {
    await assertNoDiagnostics(r'''
T bar<T>(T d) => d;

String f() {
  String h = bar('');
  return h;
}
''');
  }

  test_genericInvocation_typeNeededForInference() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar('');
  return h;
}
''');
  }

  test_genericInvocation_typeParamProvided() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar<String>('');
  return h;
}
''');
  }

  test_instanceCreation_generic() async {
    await assertDiagnostics(r'''
f() {
  A<int> a = A<int>();
}

class A<X> {}
''', [
      lint(8, 6),
    ]);
  }

  test_instanceCreation_generic_ok() async {
    await assertNoDiagnostics(r'''
f() {
  A<num> a = A<int>();
}

class A<X> {}
''');
  }

  test_instanceCreation_nonGeneric() async {
    await assertDiagnostics(r'''
f() {
  A a = A();
}

class A {}
''', [
      lint(8, 1),
    ]);
  }

  test_literal_bool() async {
    await assertDiagnostics(r'''
f() {
  bool b = true;
}
''', [
      lint(8, 4),
    ]);
  }

  test_literal_double() async {
    await assertDiagnostics(r'''
f() {
  double d = 1.5;
}
''', [
      lint(8, 6),
    ]);
  }

  // The type is not obvious.
  test_literal_doubleTypedInt() async {
    await assertNoDiagnostics(r'''
f() {
  double d = 1;
}
''');
  }

  test_literal_int() async {
    await assertDiagnostics(r'''
f() {
  int i = 1;
}
''', [
      lint(8, 3),
    ]);
  }

  // `Null` is not obvious, the inferred type is `dynamic`.
  test_literal_null() async {
    await assertNoDiagnostics(r'''
f() {
  Null nil = null;
}
''');
  }

  test_literal_string() async {
    await assertDiagnostics(r'''
f() {
  String s = "A string";
}
''', [
      lint(8, 6),
    ]);
  }

  test_literal_symbol() async {
    await assertDiagnostics(r'''
f() {
  Symbol s = #print;
}
''', [
      lint(8, 6),
    ]);
  }

  test_local_multiple() async {
    await assertDiagnostics(r'''
f() {
  String a = 'a', b = 'b';
}
''', [
      lint(8, 6),
    ]);
  }

  test_local_multiple_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var a = 'a', b = 'b';
}
''');
  }

  /// Types are considered an important part of the pattern so we
  /// intentionally do not lint on declared variable patterns.
  test_pattern_list_destructured() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_pattern_map_destructured() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_pattern_object_destructured() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: int _b) = A(1);
}
''');
  }

  test_pattern_record_destructured() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  switch (o) {
    case (int x, String s):
  }
}
''');
  }

  test_switch_pattern_object() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && int b):
  }
}
''');
  }

  test_switch_pattern_record() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (int a, final int b):
  }
}
''');
  }
}
