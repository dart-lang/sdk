// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OmitObviousPropertyTypesTest);
  });
}

@reflectiveTest
class OmitObviousPropertyTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'omit_obvious_property_types';

  test_as_dynamic_static() async {
    await assertDiagnostics(
      r'''
class A {
  static dynamic i = n as dynamic;
}

num n = 1;
''',
      [lint(19, 7)],
    );
  }

  test_as_dynamic_topLevel() async {
    await assertDiagnostics(
      r'''
dynamic i = n as dynamic;
num n = 1;
''',
      [lint(0, 7)],
    );
  }

  test_as_static() async {
    await assertDiagnostics(
      r'''
class A {
  static int i = n as int;
}

num n = 1;
''',
      [lint(19, 3)],
    );
  }

  test_as_topLevel() async {
    await assertDiagnostics(
      r'''
int i = n as int;
num n = 1;
''',
      [lint(0, 3)],
    );
  }

  test_cascade_static() async {
    await assertDiagnostics(
      r'''
class A {
  static C c = C()..x..x..x;
}

class C {
  final x = 0;
}
''',
      [lint(19, 1)],
    );
  }

  test_cascade_topLevel() async {
    await assertDiagnostics(
      r'''
C c = C()..x..x..x;

class C {
  final x = 0;
}
''',
      [lint(0, 1)],
    );
  }

  test_dot_shorthand() async {
    await assertNoDiagnostics(r'''
int i = .parse('1');
''');
  }

  test_genericInvocation_paramIsType_static() async {
    await assertNoDiagnostics(r'''
T bar<T>(T d) => d;

class A {
  static String h = bar('');
}
''');
  }

  test_genericInvocation_paramIsType_topLevel() async {
    await assertNoDiagnostics(r'''
T bar<T>(T d) => d;
String h = bar('');
''');
  }

  test_genericInvocation_typeNeededForInference_static() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

class A {
  static String h = bar('');
}
''');
  }

  test_genericInvocation_typeNeededForInference_topLevel() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;
String h = bar('');
''');
  }

  test_genericInvocation_typeParamProvided_static() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

class A {
  static String h = bar<String>('');
}
''');
  }

  test_genericInvocation_typeParamProvided_topLevel() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;
String h = bar<String>('');
''');
  }

  test_instanceCreation_generic_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static C<num> c = C<int>();
}

class C<X> {}
''');
  }

  test_instanceCreation_generic_ok_topLevel() async {
    await assertNoDiagnostics(r'''
C<num> c = C<int>();

class C<X> {}
''');
  }

  test_instanceCreation_generic_static() async {
    await assertDiagnostics(
      r'''
class A {
  static C<int> c = C<int>();
}

class C<X> {}
''',
      [lint(19, 6)],
    );
  }

  test_instanceCreation_generic_topLevel() async {
    await assertDiagnostics(
      r'''
C<int> c = C<int>();

class C<X> {}
''',
      [lint(0, 6)],
    );
  }

  test_instanceCreation_nonGeneric_static() async {
    await assertDiagnostics(
      r'''
class A {
  static C c = C();
}

class C {}
''',
      [lint(19, 1)],
    );
  }

  test_instanceCreation_nonGeneric_topLevel() async {
    await assertDiagnostics(
      r'''
C c = C();

class C {}
''',
      [lint(0, 1)],
    );
  }

  test_list_ok1_static() async {
    await assertNoDiagnostics(r'''
class A {
  static List<Object> a = [1, true, 2];
}
''');
  }

  test_list_ok1_topLevel() async {
    await assertNoDiagnostics(r'''
List<Object> a = [1, true, 2];
''');
  }

  test_list_ok2_static() async {
    await assertNoDiagnostics(r'''
class A {
  static List<Object> a = [1, foo(2), 3];
}

List<X> foo<X>(X x) => [x];
''');
  }

  test_list_ok2_topLevel() async {
    await assertNoDiagnostics(r'''
List<Object> a = [1, foo(2), 3];

List<X> foo<X>(X x) => [x];
''');
  }

  test_list_static() async {
    await assertDiagnostics(
      r'''
class A {
  static List<String> a = ['a', 'b', ('c' as dynamic) as String];
}
''',
      [lint(19, 12)],
    );
  }

  test_list_topLevel() async {
    await assertDiagnostics(
      r'''
List<String> a = ['a', 'b', ('c' as dynamic) as String];
''',
      [lint(0, 12)],
    );
  }

  test_literal_bool_static() async {
    await assertDiagnostics(
      r'''
class A {
  static bool b = true;
}
''',
      [lint(19, 4)],
    );
  }

  test_literal_bool_topLevel() async {
    await assertDiagnostics(
      r'''
bool b = true;
''',
      [lint(0, 4)],
    );
  }

  test_literal_double_static() async {
    await assertDiagnostics(
      r'''
class A {
  static double d = 1.5;
}
''',
      [lint(19, 6)],
    );
  }

  test_literal_double_topLevel() async {
    await assertDiagnostics(
      r'''
double d = 1.5;
''',
      [lint(0, 6)],
    );
  }

  // The type is not obvious.
  test_literal_doubleTypedInt_static() async {
    await assertNoDiagnostics(r'''
class A {
  static double d = 1;
}
''');
  }

  // The type is not obvious.
  test_literal_doubleTypedInt_topLevel() async {
    await assertNoDiagnostics(r'''
double d = 1;
''');
  }

  test_literal_int_static() async {
    await assertDiagnostics(
      r'''
class A {
  static int i = 1;
}
''',
      [lint(19, 3)],
    );
  }

  test_literal_int_topLevel() async {
    await assertDiagnostics(
      r'''
int i = 1;
''',
      [lint(0, 3)],
    );
  }

  // `Null` is not obvious, the inferred type is `dynamic`.
  test_literal_null_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Null nil = null;
}
''');
  }

  // `Null` is not obvious, the inferred type is `dynamic`.
  test_literal_null_topLevel() async {
    await assertNoDiagnostics(r'''
Null nil = null;
''');
  }

  test_literal_string_static() async {
    await assertDiagnostics(
      r'''
class A {
  static String s = "A string";
}
''',
      [lint(19, 6)],
    );
  }

  test_literal_string_topLevel() async {
    await assertDiagnostics(
      r'''
String s = "A string";
''',
      [lint(0, 6)],
    );
  }

  test_literal_symbol_static() async {
    await assertDiagnostics(
      r'''
class A {
  static Symbol s = #print;
}
''',
      [lint(19, 6)],
    );
  }

  test_literal_symbol_topLevel() async {
    await assertDiagnostics(
      r'''
Symbol s = #print;
''',
      [lint(0, 6)],
    );
  }

  test_local_multiple_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static var a = 'a', b = 'b';
}
''');
  }

  test_local_multiple_ok_topLevel() async {
    await assertNoDiagnostics(r'''
var a = 'a', b = 'b';
''');
  }

  test_map_ok1_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Map<Object, String> a = {1: 'a', true: 'b'};
}
''');
  }

  test_map_ok1_topLevel() async {
    await assertNoDiagnostics(r'''
Map<Object, String> a = {1: 'a', true: 'b'};
''');
  }

  test_map_ok2_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Map<int, Object> a = {1: 'a', 2: #b};
}
''');
  }

  test_map_ok2_topLevel() async {
    await assertNoDiagnostics(r'''
Map<int, Object> a = {1: 'a', 2: #b};
''');
  }

  test_map_ok3_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Map<int, String> a = {1: 'a', i: 'b'};
}

var i = 2;
''');
  }

  test_map_ok3_topLevel() async {
    await assertNoDiagnostics(r'''
Map<int, String> a = {1: 'a', i: 'b'};
var i = 2;
''');
  }

  test_map_ok4_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Map<int, String> a = {1: 'a', 2: b};
}

var b = 'b';
''');
  }

  test_map_ok4_topLevel() async {
    await assertNoDiagnostics(r'''
Map<int, String> a = {1: 'a', 2: b};
var b = 'b';
''');
  }

  test_map_static() async {
    await assertDiagnostics(
      r'''
class A {
  static Map<double, String> a = {1.5: 'a'};
}
''',
      [lint(19, 19)],
    );
  }

  test_map_topLevel() async {
    await assertDiagnostics(
      r'''
Map<double, String> a = {1.5: 'a'};
''',
      [lint(0, 19)],
    );
  }

  test_multiple_static() async {
    await assertDiagnostics(
      r'''
class A {
  static String a = 'a', b = 'b';
}
''',
      [lint(19, 6)],
    );
  }

  test_multiple_topLevel() async {
    await assertDiagnostics(
      r'''
String a = 'a', b = 'b';
''',
      [lint(0, 6)],
    );
  }
}
