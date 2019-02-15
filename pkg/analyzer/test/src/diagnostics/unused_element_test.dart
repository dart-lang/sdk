// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedElementTest);
  });
}

@reflectiveTest
class UnusedElementTest extends DriverResolutionTest {
  @override
  bool get enableUnusedElement => true;

  test_class_isUsed_extends() async {
    await assertNoErrorsInCode(r'''
class _A {}
class B extends _A {}
''');
  }

  test_class_isUsed_fieldDeclaration() async {
    await assertNoErrorsInCode(r'''
class Foo {
  _Bar x;
}

class _Bar {
}
''');
  }

  test_class_isUsed_implements() async {
    await assertNoErrorsInCode(r'''
class _A {}
class B implements _A {}
''');
  }

  test_class_isUsed_instanceCreation() async {
    await assertNoErrorsInCode(r'''
class _A {}
main() {
  new _A();
}
''');
  }

  test_class_isUsed_staticFieldAccess() async {
    await assertNoErrorsInCode(r'''
class _A {
  static const F = 42;
}
main() {
  _A.F;
}
''');
  }

  test_class_isUsed_staticMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class _A {
  static m() {}
}
main() {
  _A.m();
}
''');
  }

  test_class_isUsed_typeArgument() async {
    await assertNoErrorsInCode(r'''
class _A {}
main() {
  var v = new List<_A>();
  print(v);
}
''');
  }

  test_class_notUsed_inClassMember() async {
    await assertErrorsInCode(r'''
class _A {
  static staticMethod() {
    new _A();
  }
  instanceMethod() {
    new _A();
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_class_notUsed_inConstructorName() async {
    await assertErrorsInCode(r'''
class _A {
  _A() {}
  _A.named() {}
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_class_notUsed_isExpression() async {
    await assertErrorsInCode(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_class_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class _A {}
main() {
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_class_notUsed_variableDeclaration() async {
    await assertErrorsInCode(r'''
class _A {}
main() {
  _A v;
  print(v);
}
print(x) {}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_enum_isUsed_fieldReference() async {
    await assertNoErrorsInCode(r'''
enum _MyEnum {A, B, C}
main() {
  print(_MyEnum.B);
}
''');
  }

  test_enum_notUsed_noReference() async {
    await assertErrorsInCode(r'''
enum _MyEnum {A, B, C}
main() {
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_functionLocal_isUsed_closure() async {
    await assertNoErrorsInCode(r'''
main() {
  print(() {});
}
print(x) {}
''');
  }

  test_functionLocal_isUsed_invocation() async {
    await assertNoErrorsInCode(r'''
main() {
  f() {}
  f();
}
''');
  }

  test_functionLocal_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
main() {
  f() {}
  print(f);
}
print(x) {}
''');
  }

  test_functionLocal_notUsed_noReference() async {
    await assertErrorsInCode(r'''
main() {
  f() {}
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_functionLocal_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_functionTop_isUsed_invocation() async {
    await assertNoErrorsInCode(r'''
_f() {}
main() {
  _f();
}
''');
  }

  test_functionTop_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
_f() {}
main() {
  print(_f);
}
print(x) {}
''');
  }

  test_functionTop_notUsed_noReference() async {
    await assertErrorsInCode(r'''
_f() {}
main() {
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_functionTop_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
_f(int p) {
  _f(p - 1);
}
main() {
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_functionTypeAlias_isUsed_isExpression() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
main(f) {
  if (f is _F) {
    print('F');
  }
}
''');
  }

  test_functionTypeAlias_isUsed_reference() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
main(_F f) {
}
''');
  }

  test_functionTypeAlias_isUsed_typeArgument() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
main() {
  var v = new List<_F>();
  print(v);
}
''');
  }

  test_functionTypeAlias_isUsed_variableDeclaration() async {
    await assertNoErrorsInCode(r'''
typedef _F(a, b);
class A {
  _F f;
}
''');
  }

  test_functionTypeAlias_notUsed_noReference() async {
    await assertErrorsInCode(r'''
typedef _F(a, b);
main() {
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_getter_isUsed_invocation_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}
''');
  }

  test_getter_isUsed_invocation_PrefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  get _g => null;
}
main(A a) {
  var v = a._g;
}
''');
  }

  test_getter_isUsed_invocation_PropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''');
  }

  test_getter_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  get _g => null;
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_getter_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
class A {
  get _g {
    return _g;
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_method_isUsed_hasReference_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
print(x) {}
''');
  }

  test_method_isUsed_hasReference_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
class B extends A {
  _m() {}
}
print(x) {}
''');
  }

  test_method_isUsed_hasReference_PrefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main(A a) {
  a._m;
}
''');
  }

  test_method_isUsed_hasReference_PropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  new A()._m;
}
''');
  }

  test_method_isUsed_invocation_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
''');
  }

  test_method_isUsed_invocation_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
class B extends A {
  _m() {}
}
''');
  }

  test_method_isUsed_invocation_MemberElement() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  _m(T t) {}
}
main(A<int> a) {
  a._m(0);
}
''');
  }

  test_method_isUsed_invocation_propagated() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  var a = new A();
  a._m();
}
''');
  }

  test_method_isUsed_invocation_static() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
main() {
  A a = new A();
  a._m();
}
''');
  }

  test_method_isUsed_invocation_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
class B extends A {
  _m() {}
}
main(A a) {
  a._m();
}
''');
  }

  test_method_isUsed_notPrivate() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
main() {
}
''');
  }

  test_method_isUsed_staticInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  static _m() {}
}
main() {
  A._m();
}
''');
  }

  test_method_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  static _m() {}
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_method_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_setter_isUsed_invocation_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
  useSetter() {
    _s = 42;
  }
}
''');
  }

  test_setter_isUsed_invocation_PrefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
}
main(A a) {
  a._s = 42;
}
''');
  }

  test_setter_isUsed_invocation_PropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  set _s(x) {}
}
main() {
  new A()._s = 42;
}
''');
  }

  test_setter_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  set _s(x) {}
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_setter_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
class A {
  set _s(int x) {
    if (x > 5) {
      _s = x - 1;
    }
  }
}
''', [HintCode.UNUSED_ELEMENT]);
  }

  test_topLevelVariable_isUsed() async {
    await assertNoErrorsInCode(r'''
int _a = 1;
main() {
  _a;
}
''');
  }

  test_topLevelVariable_isUsed_plusPlus() async {
    await assertNoErrorsInCode(r'''
int _a = 0;
main() {
  var b = _a++;
  b;
}
''');
  }

  test_topLevelVariable_notUsed() async {
    await assertErrorsInCode(r'''
int _a = 1;
main() {
  _a = 2;
}
''', [HintCode.UNUSED_ELEMENT]);
  }
}
