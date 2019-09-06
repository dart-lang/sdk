// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonAbstractClassInheritsAbstractMemberTest);
  });
}

@reflectiveTest
class NonAbstractClassInheritsAbstractMemberTest extends DriverResolutionTest {
  test_fivePlus() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
}
''', [
      error(
          StaticWarningCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          62,
          1),
    ]);
  }

  test_four() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          55, 1),
    ]);
  }

  test_one_classTypeAlias_interface() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          74, 1),
    ]);
  }

  test_one_classTypeAlias_mixin() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          54, 1),
    ]);
  }

  test_one_classTypeAlias_superclass() async {
    // 15979
    await assertErrorsInCode('''
class M {}
abstract class A {
  m();
}
class B = A with M;
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45, 1),
    ]);
  }

  test_one_getter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  int get g {return 1;}
}
class C implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          42, 1),
    ]);
  }

  test_one_getter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  int get g;
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          40, 1),
    ]);
  }

  test_one_method_fromInterface() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_one_method_fromInterface_abstractNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
  noSuchMethod(v);
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_one_method_fromInterface_abstractOverrideNSM() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode('''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          55, 1),
    ]);
  }

  test_one_method_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  m(p);
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          35, 1),
    ]);
  }

  test_one_method_optionalParamCount() async {
    // 7640
    await assertErrorsInCode('''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          89, 1),
    ]);
  }

  test_one_mixinInherits_getter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          90, 1),
    ]);
  }

  test_one_mixinInherits_method() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_one_mixinInherits_setter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          96, 1),
    ]);
  }

  test_one_noSuchMethod_interface() async {
    // 15979
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          71, 1),
    ]);
  }

  test_one_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    await assertErrorsInCode('''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
  get field => 0;
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          77, 1),
    ]);
  }

  test_one_setter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  set s(int i) {}
}
class C implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36, 1),
    ]);
  }

  test_one_setter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  set s(int i);
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          43, 1),
    ]);
  }

  test_one_superclasses_interface() async {
    // bug 11154
    await assertErrorsInCode('''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_one_variable_fromInterface_missingGetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_one_variable_fromInterface_missingSetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  get v => 1;
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_three() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
          48, 1),
    ]);
  }

  test_two() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
}
class C extends A {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          41, 1),
    ]);
  }

  test_two_fromInterface_missingBoth() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
}
''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          27, 1),
    ]);
  }
}
