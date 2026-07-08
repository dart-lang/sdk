// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonAbstractClassInheritsAbstractMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonAbstractClassInheritsAbstractMemberTest
    extends PubPackageResolutionTest {
  test_abstract_field_final_implement_getter() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int x;
}
class B implements A {
  int get x => 0;
}
''');
  }

  test_abstract_field_final_implement_none() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int x;
}
class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.x'.
''');
  }

  test_abstract_field_implement_getter() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
class B implements A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.x'.
  int get x => 0;
}
''');
  }

  test_abstract_field_implement_getter_and_setter() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
class B implements A {
  int get x => 0;
  void set x(int value) {}
}
''');
  }

  test_abstract_field_implement_none() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberTwo] Missing concrete implementations of 'getter A.x' and 'setter A.x'.
''');
  }

  test_abstract_field_implement_setter() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
class B implements A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.x'.
  void set x(int value) {}
}
''');
  }

  test_abstractsDontOverrideConcretes_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get g => 0;
}
abstract class B extends A {
  int get g;
}
class C extends B {}
''');
  }

  test_abstractsDontOverrideConcretes_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m(p) {}
}
abstract class B extends A {
  m(p);
}
class C extends B {}
''');
  }

  test_abstractsDontOverrideConcretes_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set s(v) {}
}
abstract class B extends A {
  set s(v);
}
class C extends B {}
''');
  }

  test_augment_withClause_crossFile_error_nonAbstractClassInheritsAbstractMember() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin M {
  int foo();
}

class A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'M.foo'.
''',
      b: r'''
part of 'a.dart';

augment class A with M {}
''',
    });
  }

  test_augment_withClause_sameFile_error_nonAbstractClassInheritsAbstractMember() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int foo();
}

class A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'M.foo'.

augment class A with M {}
''');
  }

  test_class_abstract_implementsClause_method() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

abstract class B implements A {}
''');
  }

  test_class_concrete_implementsClause_method() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.
''');
  }

  test_class_concrete_implementsClause_method_hasClassAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.

augment class B {}
''');
  }

  test_class_concrete_implementsClause_method_hasClassAugmentation_withImplementsClause() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

class B {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.

augment class B implements A {}
''');
  }

  test_class_notAbstract_hasConcreteSubtype_method() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}

class B extends A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.

class C extends B {}

class D extends C {}
''');
  }

  test_classTypeAlias_interface() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
abstract class B = A with M implements I;
''');
  }

  test_classTypeAlias_mixin() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
abstract class M {
  m();
}
abstract class A {}
abstract class B = A with M;
''');
  }

  test_classTypeAlias_superclass() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class M {}
abstract class A {
  m();
}
abstract class B = A with M;
''');
  }

  test_enum_getter_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

enum E implements A {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.foo'.
  v;
}
''');
  }

  test_enum_getter_fromMixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  int get foo;
}

enum E with M {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter M.foo'.
  v;
}
''');
  }

  test_enum_implementsClause_method() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

enum B implements A {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.
  v;
}
''');
  }

  test_enum_implementsClause_method_hasEnumAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

enum B implements A {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.
  v;
}

augment enum B {}
''');
  }

  test_enum_implementsClause_method_hasEnumAugmentation_withImplementsClause() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

enum B {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.
  v;
}

augment enum B implements A {}
''');
  }

  test_enum_method_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

enum E implements A {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.foo'.
  v;
}
''');
  }

  test_enum_method_fromMixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  void foo();
}

enum E with M {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'M.foo'.
  v;
}
''');
  }

  test_enum_setter_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

enum E implements A {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.foo'.
  v;
}
''');
  }

  test_enum_setter_fromMixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  set foo(int _);
}

enum E with M {
//   ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter M.foo'.
  v;
}
''');
  }

  test_external_field_final_implement_getter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int x;
}
class B implements A {
  int get x => 0;
}
''');
  }

  test_external_field_final_implement_none() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int x;
}
class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.x'.
''');
  }

  test_external_field_implement_getter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
class B implements A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.x'.
  int get x => 0;
}
''');
  }

  test_external_field_implement_getter_and_setter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
class B implements A {
  int get x => 0;
  void set x(int value) {}
}
''');
  }

  test_external_field_implement_none() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
class B implements A {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberTwo] Missing concrete implementations of 'getter A.x' and 'setter A.x'.
''');
  }

  test_external_field_implement_setter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
class B implements A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.x'.
  void set x(int value) {}
}
''');
  }

  test_fivePlus() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberFivePlus] Missing concrete implementations of 'A.m', 'A.n', 'A.o', 'A.p', and 1 more.
}
''');
  }

  test_four() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberFour] Missing concrete implementations of 'A.m', 'A.n', 'A.o', and 'A.p'.
}
''');
  }

  test_mixin_concreteGetter() async {
    // issue 17034
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class A {
  var a;
}
abstract class M {
  get a;
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_mixin_concreteMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class A {
  m() {}
}
abstract class M {
  m();
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_mixin_concreteSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class A {
  var a;
}
abstract class M {
  set a(dynamic v);
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_noSuchMethod_concreteAccessor() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get g;
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_noSuchMethod_concreteMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  m(p);
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_noSuchMethod_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class A {
  noSuchMethod(v) => '';
}
class B extends Object with A {
  m(p);
}
''');
  }

  test_noSuchMethod_superclass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends A {
  m(p);
}
''');
  }

  test_one_classTypeAlias_interface() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'I.m'.
''');
  }

  test_one_classTypeAlias_mixin() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
abstract class M {
  m();
}
abstract class A {}
class B = A with M;
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'M.m'.
''');
  }

  test_one_classTypeAlias_superclass() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
class M {}
abstract class A {
  m();
}
class B = A with M;
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.m'.
''');
  }

  test_one_getter_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  int get g {return 1;}
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter I.g'.
}
''');
  }

  test_one_getter_fromSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get g;
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.g'.
}
''');
  }

  test_one_method_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  m(p) {}
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'I.m'.
}
''');
  }

  test_one_method_fromInterface_abstractNSM() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  m(p) {}
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'I.m'.
  noSuchMethod(v);
}
''');
  }

  test_one_method_fromInterface_abstractOverrideNSM() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  m(p) {}
}
class B {
  noSuchMethod(v) => null;
}
class C extends B implements I {
  noSuchMethod(v);
}
''');
  }

  test_one_method_fromInterface_ifcNSM() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'I.m'.
}
''');
  }

  test_one_method_fromSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  m(p);
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.m'.
}
''');
  }

  test_one_method_optionalParamCount() async {
    // issue 7640
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'B.x'.
}
''');
  }

  test_one_mixinInherits_getter() async {
    // issue 15001
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.g2'.
''');
  }

  test_one_mixinInherits_method() async {
    // issue 15001
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.m2'.
''');
  }

  test_one_mixinInherits_setter() async {
    // issue 15001
    await resolveTestCodeWithDiagnostics('''
//@dart=2.19
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.s2'.
''');
  }

  test_one_noSuchMethod_interface() async {
    // issue 15979
    await resolveTestCodeWithDiagnostics('''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'A.m'.
}
''');
  }

  test_one_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.field'.
  get field => 0;
}
''');
  }

  test_one_setter_fromInterface() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  set s(int i) {}
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter I.s'.
}
''');
  }

  test_one_setter_fromSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  set s(int i);
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.s'.
}
''');
  }

  test_one_superclasses_interface() async {
    // issue 11154
    await resolveTestCodeWithDiagnostics('''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter A.a'.
}
''');
  }

  test_one_variable_fromInterface_missingGetter() async {
    // issue 16133
    await resolveTestCodeWithDiagnostics('''
class I {
  var v;
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter I.v'.
  set v(_) {}
}
''');
  }

  test_one_variable_fromInterface_missingSetter() async {
    // issue 16133
    await resolveTestCodeWithDiagnostics('''
class I {
  var v;
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter I.v'.
  get v => 1;
}
''');
  }

  test_overridesConcreteMethodInObject() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
class A {
  String toString([String prefix = '']) => '${prefix}Hello';
}
class C {}
class B extends A with C {}
''');
  }

  test_three() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberThree] Missing concrete implementations of 'A.m', 'A.n', and 'A.o'.
}
''');
  }

  test_two() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  m();
  n();
}
class C extends A {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberTwo] Missing concrete implementations of 'A.m' and 'A.n'.
}
''');
  }

  test_two_fromInterface_missingBoth() async {
    // issue 16133
    await resolveTestCodeWithDiagnostics('''
class I {
  var v;
}
class C implements I {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberTwo] Missing concrete implementations of 'getter I.v' and 'setter I.v'.
}
''');
  }
}
