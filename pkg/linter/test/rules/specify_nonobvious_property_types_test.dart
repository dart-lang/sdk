// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SpecifyNonObviousPropertyTypesTest);
  });
}

@reflectiveTest
class SpecifyNonObviousPropertyTypesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.specify_nonobvious_property_types;

  test_as_dynamic_instance() async {
    await assertNoDiagnostics(r'''
class A {
  var d = 1 as dynamic;
}
''');
  }

  test_as_dynamic_static() async {
    await assertNoDiagnostics(r'''
class A {
  static var d = 1 as dynamic;
}
''');
  }

  test_as_dynamic_topLevel() async {
    await assertNoDiagnostics(r'''
var d = 1 as dynamic;
''');
  }

  test_as_instance() async {
    await assertNoDiagnostics(r'''
class A {
  var d = 1 as num;
}
''');
  }

  test_as_static() async {
    await assertNoDiagnostics(r'''
class A {
  static var d = 1 as num;
}
''');
  }

  test_as_topLevel() async {
    await assertNoDiagnostics(r'''
var d = 1 as num;
''');
  }

  test_cascade_instance() async {
    await assertNoDiagnostics(r'''
class A {
  var c = C()..x..x..x;
}

class C {
  final int x = 0;
}
''');
  }

  test_cascade_static() async {
    await assertNoDiagnostics(r'''
class A {
  static var c = C()..x..x..x;
}

class C {
  final int x = 0;
}
''');
  }

  test_cascade_topLevel() async {
    await assertNoDiagnostics(r'''
var a = A()..x..x..x;

class A {
  final int x = 0;
}
''');
  }

  test_genericInvocation_paramIsType_instance() async {
    await assertDiagnostics(r'''
class A {
  final h = bar('');
}

T bar<T>(T d) => d;
''', [
      lint(12, 17),
    ]);
  }

  test_genericInvocation_paramIsType_ok_instance() async {
    await assertNoDiagnostics(r'''
class A {
  String h = bar('');
}

T bar<T>(T d) => d;
''');
  }

  test_genericInvocation_paramIsType_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static String h = bar('');
}

T bar<T>(T d) => d;
''');
  }

  test_genericInvocation_paramIsType_ok_topLevel() async {
    await assertNoDiagnostics(r'''
String h = bar('');
T bar<T>(T d) => d;
''');
  }

  test_genericInvocation_paramIsType_static() async {
    await assertDiagnostics(r'''
class A {
  static final h = bar('');
}

T bar<T>(T d) => d;
''', [
      lint(19, 17),
    ]);
  }

  test_genericInvocation_paramIsType_topLevel() async {
    await assertDiagnostics(r'''
final h = bar('');

T bar<T>(T d) => d;
''', [
      lint(0, 17),
    ]);
  }

  test_genericInvocation_typeNeededForInference_instance() async {
    await assertDiagnostics(r'''
class A {
  static var h = bar('');
}

T bar<T>(dynamic d) => d;
''', [
      lint(19, 15),
    ]);
  }

  test_genericInvocation_typeNeededForInference_ok_instance() async {
    await assertNoDiagnostics(r'''
class A {
  String h = bar('');
}

T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeNeededForInference_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static String h = bar('');
}

T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeNeededForInference_ok_topLevel() async {
    await assertNoDiagnostics(r'''
String h = bar('');
T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeNeededForInference_static() async {
    await assertDiagnostics(r'''
class A {
  static var h = bar('');
}

T bar<T>(dynamic d) => d;
''', [
      lint(19, 15),
    ]);
  }

  test_genericInvocation_typeNeededForInference_topLevel() async {
    await assertDiagnostics(r'''
var h = bar('');
T bar<T>(dynamic d) => d;
''', [
      lint(0, 15),
    ]);
  }

  test_genericInvocation_typeParamProvided_instance() async {
    await assertDiagnostics(r'''
class A {
  var h = bar<String>('');
}

T bar<T>(dynamic d) => d;
''', [
      lint(12, 23),
    ]);
  }

  test_genericInvocation_typeParamProvided_ok_instance() async {
    await assertNoDiagnostics(r'''
class A {
  String h = bar<String>('');
}

T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeParamProvided_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static String h = bar<String>('');
}

T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeParamProvided_ok_topLevel() async {
    await assertNoDiagnostics(r'''
String h = bar<String>('');
T bar<T>(dynamic d) => d;
''');
  }

  test_genericInvocation_typeParamProvided_static() async {
    await assertDiagnostics(r'''
class A {
  static var h = bar<String>('');
}

T bar<T>(dynamic d) => d;
''', [
      lint(19, 23),
    ]);
  }

  test_genericInvocation_typeParamProvided_topLevel() async {
    await assertDiagnostics(r'''
var h = bar<String>('');
T bar<T>(dynamic d) => d;
''', [
      lint(0, 23),
    ]);
  }

  test_instanceCreation_generic_instance() async {
    await assertDiagnostics(r'''
class A {
  var c = C(1);
}

class C<X> {
  C(X x);
}
''', [
      lint(12, 12),
    ]);
  }

  test_instanceCreation_generic_ok1_instance() async {
    await assertNoDiagnostics(r'''
class A {
  C<int> c = C<int>();
}

class C<X> {}
''');
  }

  test_instanceCreation_generic_ok1_static() async {
    await assertNoDiagnostics(r'''
class A {
  static C<int> c = C<int>();
}

class C<X> {}
''');
  }

  test_instanceCreation_generic_ok1_topLevel() async {
    await assertNoDiagnostics(r'''
A<int> a = A<int>();

class A<X> {}
''');
  }

  test_instanceCreation_generic_ok2_instance() async {
    await assertNoDiagnostics(r'''
class A {
  C<num> a = C<int>();
}

class C<X> {}
''');
  }

  test_instanceCreation_generic_ok2_static() async {
    await assertNoDiagnostics(r'''
class A {
  static C<num> a = C<int>();
}

class C<X> {}
''');
  }

  test_instanceCreation_generic_ok2_topLevel() async {
    await assertNoDiagnostics(r'''
A<num> a = A<int>();

class A<X> {}
''');
  }

  test_instanceCreation_generic_static() async {
    await assertDiagnostics(r'''
class A {
  static var c = C(1);
}

class C<X> {
  C(X x);
}
''', [
      lint(19, 12),
    ]);
  }

  test_instanceCreation_generic_topLevel() async {
    await assertDiagnostics(r'''
var a = A(1);

class A<X> {
  A(X x);
}
''', [
      lint(0, 12),
    ]);
  }

  test_instanceCreation_nonGeneric_instance() async {
    await assertNoDiagnostics(r'''
class A {
  C c = C();
}

class C {}
''');
  }

  test_instanceCreation_nonGeneric_static() async {
    await assertNoDiagnostics(r'''
class A {
  static C c = C();
}

class C {}
''');
  }

  test_instanceCreation_nonGeneric_topLevel() async {
    await assertNoDiagnostics(r'''
A a = A();

class A {}
''');
  }

  test_literal_bool_instance() async {
    await assertNoDiagnostics(r'''
class A {
  static bool b = true;
}
''');
  }

  test_literal_bool_static() async {
    await assertNoDiagnostics(r'''
class A {
  static bool b = true;
}
''');
  }

  test_literal_bool_topLevel() async {
    await assertNoDiagnostics(r'''
bool b = true;
''');
  }

  test_literal_double_instance() async {
    await assertNoDiagnostics(r'''
class A {
  double d = 1.5;
}
''');
  }

  test_literal_double_static() async {
    await assertNoDiagnostics(r'''
class A {
  static double d = 1.5;
}
''');
  }

  test_literal_double_topLevel() async {
    await assertNoDiagnostics(r'''
double d = 1.5;
''');
  }

  // The type is not obvious.
  test_literal_doubleTypedInt_instance() async {
    await assertNoDiagnostics(r'''
class A {
  double d = 1;
}
''');
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

  test_literal_int_instance() async {
    await assertNoDiagnostics(r'''
class A {
  int i = 1;
}
''');
  }

  test_literal_int_static() async {
    await assertNoDiagnostics(r'''
class A {
  static int i = 1;
}
''');
  }

  test_literal_int_topLevel() async {
    await assertNoDiagnostics(r'''
int i = 1;
''');
  }

  // `Null` is not obvious, the inferred type is `dynamic`.
  test_literal_null_instance() async {
    await assertNoDiagnostics(r'''
class A {
  Null nil = null;
}
''');
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

  test_literal_string_instance() async {
    await assertNoDiagnostics(r'''
class A {
  String s = "A string";
}
''');
  }

  test_literal_string_static() async {
    await assertNoDiagnostics(r'''
class A {
  static String s = "A string";
}
''');
  }

  test_literal_string_topLevel() async {
    await assertNoDiagnostics(r'''
String s = "A string";
''');
  }

  test_literal_symbol_instance() async {
    await assertNoDiagnostics(r'''
class A {
  Symbol s = #print;
}
''');
  }

  test_literal_symbol_static() async {
    await assertNoDiagnostics(r'''
class A {
  static Symbol s = #print;
}
''');
  }

  test_literal_symbol_topLevel() async {
    await assertNoDiagnostics(r'''
Symbol s = #print;
''');
  }

  test_multiple_instance() async {
    await assertDiagnostics(r'''
class A {
  var a = 'a' + 'a', b = 'b' * 2;
}
''', [
      lint(16, 13),
      lint(31, 11),
    ]);
  }

  test_multiple_ok_instance() async {
    await assertNoDiagnostics(r'''
class A {
  String a = 'a' + 'a', b = 'b'.toString();
}
''');
  }

  test_multiple_ok_static() async {
    await assertNoDiagnostics(r'''
class A {
  static String a = 'a' + 'a', b = 'b'.toString();
}
''');
  }

  test_multiple_ok_topLevel() async {
    await assertNoDiagnostics(r'''
String a = 'a' + 'a', b = 'b'.toString();
''');
  }

  test_multiple_static() async {
    await assertDiagnostics(r'''
class A {
  static var a = 'a' + 'a', b = 'b' * 2;
}
''', [
      lint(23, 13),
      lint(38, 11),
    ]);
  }

  test_multiple_topLevel() async {
    await assertDiagnostics(r'''
var a = 'a' + 'a', b = 'b' * 2;
''', [
      lint(4, 13),
      lint(19, 11),
    ]);
  }

  test_override_getter_initialized() async {
    await assertNoDiagnostics(r'''
class B implements A {
  var x = 'Hello, ' + 'world!';
}

abstract class A {
  String get x;
}
''');
  }

  test_override_getter_uninitialized() async {
    await assertNoDiagnostics(r'''
class B implements A {
  var x;
  B(this.x);
}

abstract class A {
  int get x;
}
''');
  }

  test_override_setter_initialized() async {
    await assertNoDiagnostics(r'''
class B implements A {
  var x = 'Hello, ' + 'world!';
}

abstract class A {
  set x (String _);
}
''');
  }

  test_override_setter_uninitialized() async {
    await assertNoDiagnostics(r'''
class B implements A {
  var x;
  B(this.x);
}

abstract class A {
  set x(int _);
}
''');
  }
}
