// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SpecifyNonObviousLocalVariableTypesTest);
  });
}

@reflectiveTest
class SpecifyNonObviousLocalVariableTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'specify_nonobvious_local_variable_types';

  test_as() async {
    await assertNoDiagnostics(r'''
f() {
  var d = 1 as num;
}
''');
  }

  test_as_dynamic() async {
    await assertNoDiagnostics(r'''
f() {
  var d = 1 as dynamic;
}
''');
  }

  test_cascade() async {
    await assertNoDiagnostics(r'''
f() {
  var a = A()..x..x..x;
}

class A {
  final x = 0;
}
''');
  }

  test_forEach_inferredList() async {
    await assertDiagnostics(r'''
f() {
  for (var i in [1, 2, 'Hello'.length]) {
    print(i);
  }
}
''', [
      lint(13, 5),
    ]);
  }

  test_forEach_listWithNonObviousElement() async {
    await assertDiagnostics(r'''
f() {
  int j = "Hello".length;
  for (var i in [j, 1, j + 1]) { }
}
''', [
      lint(39, 5),
    ]);
  }

  test_forEach_noDeclaredType() async {
    await assertNoDiagnostics(r'''
f() {
  for (var i in <int>[1, 2, 3]) { }
}
''');
  }

  test_forEach_nonObviousIterable() async {
    await assertNoDiagnostics(r'''
f() {
  for (int i in list) { }
}
var list = <int>[1, 2, 3];
''');
  }

  test_forEach_typedList() async {
    await assertNoDiagnostics(r'''
f() {
  for (int i in <int>[1, 2, 3]) { }
}
''');
  }

  test_genericInvocation_paramIsType() async {
    await assertDiagnostics(r'''
String f() {
  final h = bar('');
  return h;
}

T bar<T>(T d) => d;
''', [
      lint(15, 17),
    ]);
  }

  test_genericInvocation_paramIsType_ok() async {
    await assertNoDiagnostics(r'''
String f() {
  String h = bar('');
  return h;
}

T bar<T>(T d) => d;
''');
  }

  test_genericInvocation_typeNeededForInference() async {
    await assertDiagnostics(r'''
f() {
  var h = bar('');
  return h;
}

T bar<T>(dynamic d) => d;
''', [
      lint(8, 15),
    ]);
  }

  test_genericInvocation_typeNeededForInference_ok() async {
    await assertNoDiagnostics(r'''
String f() {
  String h = bar('');
  return h;
}

T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeParamProvided() async {
    await assertDiagnostics(r'''
String f() {
  var h = bar<String>('');
  return h;
}

T bar<T>(dynamic d) => d;
''', [
      lint(15, 23),
    ]);
  }

  test_genericInvocation_typeParamProvided_ok() async {
    await assertNoDiagnostics(r'''
String f() {
  String h = bar<String>('');
  return h;
}

T bar<T>(dynamic d) => d;
''');
  }

  test_instanceCreation_generic() async {
    await assertDiagnostics(r'''
f() {
  var a = A(1);
}

class A<X> {
  A(X x);
}
''', [
      lint(8, 12),
    ]);
  }

  test_instanceCreation_generic_ok1() async {
    await assertNoDiagnostics(r'''
f() {
  A<int> a = A<int>();
}

class A<X> {}
''');
  }

  test_instanceCreation_generic_ok2() async {
    await assertNoDiagnostics(r'''
f() {
  A<num> a = A<int>();
}

class A<X> {}
''');
  }

  test_instanceCreation_nonGeneric() async {
    await assertNoDiagnostics(r'''
f() {
  A a = A();
}

class A {}
''');
  }

  test_literal_bool() async {
    await assertNoDiagnostics(r'''
f() {
  bool b = true;
}
''');
  }

  test_literal_double() async {
    await assertNoDiagnostics(r'''
f() {
  double d = 1.5;
}
''');
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
    await assertNoDiagnostics(r'''
f() {
  int i = 1;
}
''');
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
    await assertNoDiagnostics(r'''
f() {
  String s = "A string";
}
''');
  }

  test_literal_symbol() async {
    await assertNoDiagnostics(r'''
f() {
  Symbol s = #print;
}
''');
  }

  test_local_multiple() async {
    await assertDiagnostics(r'''
f() {
  var a = 'a' + 'a', b = 'b' * 2;
}
''', [
      lint(12, 13),
      lint(27, 11),
    ]);
  }

  test_local_multiple_ok() async {
    await assertNoDiagnostics(r'''
f() {
  String a = 'a' + 'a', b = 'b'.toString();
}
''');
  }

  test_local_no_promotion() async {
    await assertNoDiagnostics(r'''
f() {
  num local = 2;
  var x = local;
  return x;
}
''');
  }

  test_local_promotion() async {
    await assertDiagnostics(r'''
f() {
  num local = 2;
  if (local is! int) return;
  var x = local;
  return x;
}
''', [
      lint(54, 13),
    ]);
  }

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
