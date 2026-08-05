// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidOverrideTest extends PubPackageResolutionTest {
  test_abstract_field_covariant_inheritance() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  void set x(Object value); // Implicitly covariant
}
abstract class C implements B {
  int get x;
  void set x(int value); // Ok because covariant
}
''');
  }

  test_class_augment_method_covariant_multiFile_invalid() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void foo(num a) {}
}

class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B {
  void foo(covariant String a) {}
//     ^^^
// [diag.invalidOverride] 'B.foo' ('void Function(String)') isn't a valid override of 'A.foo' ('void Function(num)').
}
''',
    });
  }

  test_class_augment_method_covariant_multiFile_valid() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void foo(num a) {}
}

class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B {
  void foo(covariant int a) {}
}
''',
    });
  }

  test_class_augment_method_covariant_singleFile_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(num a) {}
}

class B extends A {}

augment class B {
  void foo(covariant String a) {}
//     ^^^
// [diag.invalidOverride] 'B.foo' ('void Function(String)') isn't a valid override of 'A.foo' ('void Function(num)').
}
''');
  }

  test_class_augment_method_covariant_singleFile_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(num a) {}
}

class B extends A {}

augment class B {
  void foo(covariant int a) {}
}
''');
  }

  test_class_augment_method_multiFile() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  int foo() => 0;
//    ^^^
// [context 1] The member being overridden.
}

class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B {
  String foo() => '';
//       ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('String Function()') isn't a valid override of 'A.foo' ('int Function()').
}
''',
    });
  }

  test_class_augment_method_singleFile() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
//    ^^^
// [context 1] The member being overridden.
}

class B extends A {}

augment class B {
  String foo() => '';
//       ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('String Function()') isn't a valid override of 'A.foo' ('int Function()').
}
''');
  }

  test_class_augment_setter_multiFile() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void set foo(int value) {}
//         ^^^
// [context 1] The setter being overridden.
}

class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B {
  void set foo(String value) {}
//         ^^^
// [diag.invalidOverrideSetter][context 1] The setter 'B.foo' ('void Function(String)') isn't a valid override of 'A.foo' ('void Function(int)').
}
''',
    });
  }

  test_class_augment_setter_singleFile() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set foo(int value) {}
//         ^^^
// [context 1] The setter being overridden.
}

class B extends A {}

augment class B {
  void set foo(String value) {}
//         ^^^
// [diag.invalidOverrideSetter][context 1] The setter 'B.foo' ('void Function(String)') isn't a valid override of 'A.foo' ('void Function(int)').
}
''');
  }

  test_class_augment_withClause_multiFile__declaration0_augment1_augment1() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
part 'c.dart';

mixin M1 {}
mixin M2 {}

class A {}
''',
      b: r'''
part of 'a.dart';

augment class A with M1 {}
''',
      c: r'''
part of 'a.dart';

augment class A with M2 {}
''',
    });
  }

  test_class_augment_withClause_multiFile_declaration0_augment2() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin M1 {}
mixin M2 {}

class A {}
''',
      b: r'''
part of 'a.dart';

augment class A with M1, M2 {}
''',
    });
  }

  test_class_augment_withClause_multiFile_declaration1_augment1() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin M1 {}
mixin M2 {}

class A with M1 {}
''',
      b: r'''
part of 'a.dart';

augment class A with M2 {}
''',
    });
  }

  test_class_augment_withClause_singleFile_declaration0_augment1() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class A {}

augment class A with M {}
''');
  }

  test_class_augment_withClause_singleFile_declaration0_augment1_augment1() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 {}

class A {}

augment class A with M1 {}

augment class A with M2 {}
''');
  }

  test_class_augment_withClause_singleFile_declaration0_augment2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 {}

class A {}

augment class A with M1, M2 {}
''');
  }

  test_class_augment_withClause_singleFile_declaration1_augment1() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 {}

class A with M1 {}

augment class A with M2 {}
''');
  }

  test_class_augment_withClause_twoFiles_declaration0_augment1() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin M {}

class A {}
''',
      b: r'''
part of 'a.dart';

augment class A with M {}
''',
    });
  }

  test_class_declaringFormalParameter_covariantVar_implements_setter_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}

abstract class I {
  set foo(A value);
}

class C(covariant var B foo) implements I;
''');
  }

  test_class_declaringFormalParameter_final_extends_getter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get foo;
//        ^^^
// [context 1] The member being overridden.
}
class B(final num foo) extends A;
//                ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('num Function()') isn't a valid override of 'A.foo' ('int Function()').
''');
  }

  test_class_declaringFormalParameter_final_extends_getter_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  num get foo;
}
class B(final int foo) extends A;
''');
  }

  test_class_declaringFormalParameter_final_with_getter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  int get foo;
//        ^^^
// [context 1] The member being overridden.
}
class A(final num foo) with M;
//                ^^^
// [diag.invalidOverride][context 1] 'A.foo' ('num Function()') isn't a valid override of 'M.foo' ('int Function()').
''');
  }

  test_class_declaringFormalParameter_final_with_getter_valid() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  num get foo;
}
class A(final int foo) with M;
''');
  }

  test_class_declaringFormalParameter_var_implements_getter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get foo;
//        ^^^
// [context 1] The member being overridden.
}
class B(var num foo) implements A;
//              ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('num Function()') isn't a valid override of 'A.foo' ('int Function()').
''');
  }

  test_class_declaringFormalParameter_var_implements_getter_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  num get foo;
}
class B(var int foo) implements A;
''');
  }

  test_class_declaringFormalParameter_var_implements_getterSetter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract String foo;
//                ^^^
// [context 1] The member being overridden.
// [context 2] The setter being overridden.
}
class B(var int foo) implements A;
//              ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('int Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverrideSetter][context 2] The setter 'B.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(String)').
''');
  }

  test_class_declaringFormalParameter_var_implements_getterSetter_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int foo;
}
class B(var int foo) implements A;
''');
  }

  test_class_declaringFormalParameter_var_implements_setter_inheritsCovariant_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}

class C(covariant var A foo);
class D(var B foo) implements C;
''');
  }

  test_class_declaringFormalParameter_var_implements_setter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  set foo(num value);
//    ^^^
// [context 1] The setter being overridden.
}
class B(var int foo) implements A;
//              ^^^
// [diag.invalidOverrideSetter][context 1] The setter 'B.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(num)').
''');
  }

  test_class_declaringFormalParameter_var_implements_setter_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  set foo(int value);
}
class B(var num foo) implements A;
''');
  }

  test_enum_declaringFormalParameter_final_implements_getter_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get foo;
//        ^^^
// [context 1] The member being overridden.
}
enum E(final num foo) implements A {
//               ^^^
// [diag.invalidOverride][context 1] 'E.foo' ('num Function()') isn't a valid override of 'A.foo' ('int Function()').
  v(0)
}
''');
  }

  test_enum_declaringFormalParameter_final_implements_getter_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  num get foo;
}
enum E(final int foo) implements A {
  v(0)
}
''');
  }

  test_external_field_covariant_inheritance() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  external covariant num x;
}
abstract class B implements A {
  void set x(Object value); // Implicitly covariant
}
abstract class C implements B {
  int get x;
  void set x(int value); // Ok because covariant
}
''');
  }

  test_getter_overrides_abstract_field_covariant_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract covariant int x;
//                       ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_abstract_field_covariant_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_abstract_field_final_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int x;
//                   ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_abstract_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_abstract_field_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
//             ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_abstract_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_covariant_invalid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external covariant int x;
//                       ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_external_field_covariant_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external covariant num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_final_invalid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int x;
//                   ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_external_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_invalid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
//             ^
// [context 1] The member being overridden.
}
abstract class B implements A {
  num get x;
//        ^
// [diag.invalidOverride][context 1] 'B.x' ('num Function()') isn't a valid override of 'A.x' ('int Function()').
  void set x(num value);
}
''');
  }

  test_getter_overrides_external_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_returnType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get g { return 0; }
//        ^
// [context 1] The member being overridden.
}
class B extends A {
  String get g { return 'a'; }
//           ^
// [diag.invalidOverride][context 1] 'B.g' ('String Function()') isn't a valid override of 'A.g' ('int Function()').
}
''');
  }

  test_getter_returnType_implicit() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  String? f;
//        ^
// [context 1] The member being overridden.
// [context 2] The setter being overridden.
}
class B extends A {
  int? f;
//     ^
// [diag.invalidOverride][context 1] 'B.f' ('int? Function()') isn't a valid override of 'A.f' ('String? Function()').
// [diag.invalidOverrideSetter][context 2] The setter 'B.f' ('void Function(int?)') isn't a valid override of 'A.f' ('void Function(String?)').
}
''');
  }

  test_getter_returnType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_11.dart
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  int get getter => 0;
//        ^^^^^^
// [context 1] The member being overridden.
}
abstract class J {
  num get getter => 0;
}
abstract class A implements I, J {}
class B extends A {
  String get getter => '';
//           ^^^^^^
// [diag.invalidOverride][context 1] 'B.getter' ('String Function()') isn't a valid override of 'I.getter' ('int Function()').
}
''');
  }

  test_getter_returnType_twoInterfaces_conflicting() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I<U> {
  U get g => throw 0;
//      ^
// [context 1] The member being overridden.
}
abstract class J<V> {
  V get g => throw 0;
//      ^
// [context 2] The member being overridden.
}
class B implements I<int>, J<String> {
  double get g => throw 0;
//           ^
// [diag.invalidOverride][context 1] 'B.g' ('double Function()') isn't a valid override of 'I.g' ('int Function()').
// [diag.invalidOverride][context 2] 'B.g' ('double Function()') isn't a valid override of 'J.g' ('String Function()').
}
''');
  }

  test_issue48468() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo<T extends R, R>();
}

class B implements A {
  void foo<T extends R, R>() {}
}
''');
  }

  test_method_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics('''
class A	{
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
class B	extends A {
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function(int, int)') isn't a valid concrete implementation of 'B.add' ('int Function()').
  int add();
//    ^^^
// [diag.invalidOverride][context 1] 'B.add' ('int Function()') isn't a valid override of 'A.add' ('int Function(int, int)').
}
''');
  }

  test_method_abstractOverridesConcreteInMixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
class A with M {
//    ^
// [diag.invalidImplementationOverride] 'M.add' ('int Function(int, int)') isn't a valid concrete implementation of 'A.add' ('int Function()').
  int add();
//    ^^^
// [diag.invalidOverride][context 1] 'A.add' ('int Function()') isn't a valid override of 'M.add' ('int Function(int, int)').
}
''');
  }

  test_method_abstractOverridesConcreteViaMixin() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
mixin M {
  int add();
}
class B	extends A with M {}
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function(int, int)') isn't a valid concrete implementation of 'M.add' ('int Function()').
//                     ^
// [diag.invalidOverride][context 1] 'M.add' ('int Function()') isn't a valid override of 'A.add' ('int Function(int, int)').
''');
  }

  test_method_covariant_1() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A<T> {
  A<U> foo<U>(covariant A<Map<T, U>> a);
}

abstract class B<U, T> extends A<T> {
  B<U, V> foo<V>(B<U, Map<T, V>> a);
}
''');
  }

  test_method_covariant_2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  R foo<R>(VA<R> v);
}

abstract class B implements A {
  R foo<R>(covariant VB<R> v);
}

abstract class VA<T> {}

abstract class VB<T> implements VA<T> {}
''');
  }

  test_method_covariant_3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(num a) {}
}

class B extends A {
  void foo(dynamic a) {}
}

class C extends B {
  void foo(covariant String a) {}
//     ^^^
// [diag.invalidOverride] 'C.foo' ('void Function(String)') isn't a valid override of 'A.foo' ('void Function(num)').
}
''');
  }

  test_method_named_fewerNamedParameters() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m({a, b}) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m({a}) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function({dynamic a})') isn't a valid override of 'A.m' ('dynamic Function({dynamic a, dynamic b})').
}
''');
  }

  test_method_named_missingNamedParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m({a, b}) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m({a, c}) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function({dynamic a, dynamic c})') isn't a valid override of 'A.m' ('dynamic Function({dynamic a, dynamic b})').
}
''');
  }

  test_method_namedParamType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m({int? a}) {}
//^
// [context 1] The member being overridden.
}
class B implements A {
  m({String? a}) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function({String? a})') isn't a valid override of 'A.m' ('dynamic Function({int? a})').
}
''');
  }

  test_method_normalParamType_interface() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m(int a) {}
//^
// [context 1] The member being overridden.
}
class B implements A {
  m(String a) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(String)') isn't a valid override of 'A.m' ('dynamic Function(int)').
}
''');
  }

  test_method_normalParamType_superclass() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m(int a) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m(String a) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(String)') isn't a valid override of 'A.m' ('dynamic Function(int)').
}
''');
  }

  test_method_normalParamType_superclass_interface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I<U> {
  void m(U u) => null;
//     ^
// [context 1] The member being overridden.
}
abstract class J<V> {
  void m(V v) => null;
//     ^
// [context 2] The member being overridden.
}
class B extends I<int> implements J<String> {
  void m(double d) {}
//     ^
// [diag.invalidOverride][context 1] 'B.m' ('void Function(double)') isn't a valid override of 'I.m' ('void Function(int)').
// [diag.invalidOverride][context 2] 'B.m' ('void Function(double)') isn't a valid override of 'J.m' ('void Function(String)').
}
''');
  }

  test_method_normalParamType_twoInterfaces() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  m(int n);
}
abstract class J {
  m(num n);
//^
// [context 1] The member being overridden.
}
abstract class A implements I, J {}
class B extends A {
  m(String n) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(String)') isn't a valid override of 'J.m' ('dynamic Function(num)').
}
''');
  }

  test_method_normalParamType_twoInterfaces_conflicting() async {
    // language/override_inheritance_generic_test/08
    await resolveTestCodeWithDiagnostics('''
abstract class I<U> {
  void m(U u) => null;
//     ^
// [context 1] The member being overridden.
}
abstract class J<V> {
  void m(V v) => null;
//     ^
// [context 2] The member being overridden.
}
class B implements I<int>, J<String> {
  void m(double d) {}
//     ^
// [diag.invalidOverride][context 1] 'B.m' ('void Function(double)') isn't a valid override of 'I.m' ('void Function(int)').
// [diag.invalidOverride][context 2] 'B.m' ('void Function(double)') isn't a valid override of 'J.m' ('void Function(String)').
}
''');
  }

  test_method_optionalParamType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m([int? a]) {}
//^
// [context 1] The member being overridden.
}
class B implements A {
  m([String? a]) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function([String?])') isn't a valid override of 'A.m' ('dynamic Function([int?])').
}
''');
  }

  test_method_optionalParamType_twoInterfaces() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  m([int? n]);
}
abstract class J {
  m([num? n]);
//^
// [context 1] The member being overridden.
}
abstract class A implements I, J {}
class B extends A {
  m([String? n]) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function([String?])') isn't a valid override of 'J.m' ('dynamic Function([num?])').
}
''');
  }

  test_method_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m([a, b]) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m([a]) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function([dynamic])') isn't a valid override of 'A.m' ('dynamic Function([dynamic, dynamic])').
}
''');
  }

  test_method_positional_optionalAndRequired() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m(a, b, [c, d]) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m(a, b, [c]) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(dynamic, dynamic, [dynamic])') isn't a valid override of 'A.m' ('dynamic Function(dynamic, dynamic, [dynamic, dynamic])').
}
''');
  }

  test_method_positional_optionalAndRequired2() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m(a, b, [c, d]) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m(a, [c, d]) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(dynamic, [dynamic, dynamic])') isn't a valid override of 'A.m' ('dynamic Function(dynamic, dynamic, [dynamic, dynamic])').
}
''');
  }

  test_method_required() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  m(a) {}
//^
// [context 1] The member being overridden.
}
class B extends A {
  m(a, b) {}
//^
// [diag.invalidOverride][context 1] 'B.m' ('dynamic Function(dynamic, dynamic)') isn't a valid override of 'A.m' ('dynamic Function(dynamic)').
}
''');
  }

  test_method_returnType_interface() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int m() { return 0; }
//    ^
// [context 1] The member being overridden.
}
class B implements A {
  String m() { return 'a'; }
//       ^
// [diag.invalidOverride][context 1] 'B.m' ('String Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_method_returnType_interface_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
//    ^^^
// [context 1] The member being overridden.
}

class B {
  String foo() => '';
//       ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('String Function()') isn't a valid override of 'A.foo' ('int Function()').
}

augment class B implements A {}
''');
  }

  test_method_returnType_interface_grandparent() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int m();
//    ^
// [context 1] The member being overridden.
}
abstract class B implements A {
}
class C implements B {
  String m() { return 'a'; }
//       ^
// [diag.invalidOverride][context 1] 'C.m' ('String Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_method_returnType_mixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin class A {
  int m() { return 0; }
//    ^
// [context 1] The member being overridden.
}
class B extends Object with A {
  String m() { return 'a'; }
//       ^
// [diag.invalidOverride][context 1] 'B.m' ('String Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_method_returnType_superclass() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int m() { return 0; }
//    ^
// [context 1] The member being overridden.
}
class B extends A {
  String m() { return 'a'; }
//       ^
// [diag.invalidOverride][context 1] 'B.m' ('String Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_method_returnType_superclass_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
//    ^^^
// [context 1] The member being overridden.
}

class B {
  String foo() => '';
//       ^^^
// [diag.invalidOverride][context 1] 'B.foo' ('String Function()') isn't a valid override of 'A.foo' ('int Function()').
}

augment class B extends A {}
''');
  }

  test_method_returnType_superclass_grandparent() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int m() { return 0; }
//    ^
// [context 1] The member being overridden.
}
class B extends A {
}
class C extends B {
  String m() { return 'a'; }
//       ^
// [diag.invalidOverride][context 1] 'C.m' ('String Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_method_returnType_twoInterfaces() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  int m();
//    ^
// [context 1] The member being overridden.
}
abstract class J {
  num m();
}
abstract class A implements I, J {}
class B extends A {
  String m() => '';
//       ^
// [diag.invalidOverride][context 1] 'B.m' ('String Function()') isn't a valid override of 'I.m' ('int Function()').
}
''');
  }

  test_method_returnType_void() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int m() { return 0; }
//    ^
// [context 1] The member being overridden.
}
class B extends A {
  void m() {}
//     ^
// [diag.invalidOverride][context 1] 'B.m' ('void Function()') isn't a valid override of 'A.m' ('int Function()').
}
''');
  }

  test_mixin_field_type_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String foo = '';
//       ^^^
// [context 1] The member being overridden.
// [context 2] The setter being overridden.
}

mixin M on A {
  int foo = 0;
//    ^^^
// [diag.invalidOverride][context 1] 'M.foo' ('int Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverrideSetter][context 2] The setter 'M.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(String)').
}
''');
  }

  test_mixin_getter_type_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String get foo => '';
//           ^^^
// [context 1] The member being overridden.
}

mixin M on A {
  int get foo => 0;
//        ^^^
// [diag.invalidOverride][context 1] 'M.foo' ('int Function()') isn't a valid override of 'A.foo' ('String Function()').
}
''');
  }

  test_mixin_method_returnType_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String foo() => '';
//       ^^^
// [context 1] The member being overridden.
}

mixin M on A {
  int foo() => 0;
//    ^^^
// [diag.invalidOverride][context 1] 'M.foo' ('int Function()') isn't a valid override of 'A.foo' ('String Function()').
}
''');
  }

  test_mixin_method_returnType_on_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
//    ^^^
// [context 1] The member being overridden.
}

mixin M {
  String foo() => '';
//       ^^^
// [diag.invalidOverride][context 1] 'M.foo' ('String Function()') isn't a valid override of 'A.foo' ('int Function()').
}

augment mixin M on A {}
''');
  }

  test_mixin_setter_type_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(String _) {}
//    ^^^
// [context 1] The setter being overridden.
}

mixin M on A {
  set foo(int _) {}
//    ^^^
// [diag.invalidOverrideSetter][context 1] The setter 'M.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(String)').
}
''');
  }

  test_setter_normalParamType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set s(int v) {}
//         ^
// [context 1] The setter being overridden.
}
class B extends A {
  void set s(String v) {}
//         ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.s' ('void Function(String)') isn't a valid override of 'A.s' ('void Function(int)').
}
''');
  }

  test_setter_normalParamType_superclass_interface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
//    ^^^^^^^^
// [context 1] The setter being overridden.
}
abstract class A extends I implements J {}
class B extends A {
  set setter14(String _) => null;
//    ^^^^^^^^
// [diag.invalidOverrideSetter][context 1] The setter 'B.setter14' ('void Function(String)') isn't a valid override of 'J.setter14' ('void Function(num)').
}
''');
  }

  test_setter_normalParamType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_34.dart
    await resolveTestCodeWithDiagnostics('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
//    ^^^^^^^^
// [context 1] The setter being overridden.
}
abstract class A implements I, J {}
class B extends A {
  set setter14(String _) => null;
//    ^^^^^^^^
// [diag.invalidOverrideSetter][context 1] The setter 'B.setter14' ('void Function(String)') isn't a valid override of 'J.setter14' ('void Function(num)').
}
''');
  }

  test_setter_normalParamType_twoInterfaces_conflicting() async {
    await resolveTestCodeWithDiagnostics('''
abstract class I<U> {
  set s(U u) {}
//    ^
// [context 1] The setter being overridden.
}
abstract class J<V> {
  set s(V v) {}
//    ^
// [context 2] The setter being overridden.
}
class B implements I<int>, J<String> {
  set s(double d) {}
//    ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.s' ('void Function(double)') isn't a valid override of 'I.s' ('void Function(int)').
// [diag.invalidOverrideSetter][context 2] The setter 'B.s' ('void Function(double)') isn't a valid override of 'J.s' ('void Function(String)').
}
''');
  }

  test_setter_overrides_abstract_field_covariant_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_abstract_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_abstract_field_invalid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract num x;
//             ^
// [context 1] The setter being overridden.
}
abstract class B implements A {
  int get x;
  void set x(int value);
//         ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.x' ('void Function(int)') isn't a valid override of 'A.x' ('void Function(num)').
}
''');
  }

  test_setter_overrides_abstract_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
abstract class B implements A {
  void set x(num value);
}
''');
  }

  test_setter_overrides_external_field_covariant_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external covariant num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_external_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_external_field_invalid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external num x;
//             ^
// [context 1] The setter being overridden.
}
abstract class B implements A {
  int get x;
  void set x(int value);
//         ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.x' ('void Function(int)') isn't a valid override of 'A.x' ('void Function(num)').
}
''');
  }

  test_setter_overrides_external_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
abstract class B implements A {
  void set x(num value);
}
''');
  }
}
