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
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 2),
      error(HintCode.UNUSED_ELEMENT, 20, 12),
    ]);
  }

  test_class_notUsed_inConstructorName() async {
    await assertErrorsInCode(r'''
class _A {
  _A() {}
  _A.named() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 2),
    ]);
  }

  test_class_notUsed_isExpression() async {
    await assertErrorsInCode(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 2),
    ]);
  }

  test_class_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class _A {}
main() {
}
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 2),
    ]);
  }

  test_class_notUsed_variableDeclaration() async {
    await assertErrorsInCode(r'''
class _A {}
main() {
  _A v;
  print(v);
}
print(x) {}
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 2),
    ]);
  }

  test_constructor_isUsed_asRedirectee() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
  factory A.b() = A._constructor;
}
''');
  }

  test_constructor_isUsed_asRedirectee_viaInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
  A() : this._constructor();
}
''');
  }

  test_constructor_isUsed_asRedirectee_viaSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}

class B extends A {
  B() : super._constructor();
}
''');
  }

  test_constructor_isUsed_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}
A f() => A._constructor();
''');
  }

  test_constructor_notUsed_multiple() async {
    await assertErrorsInCode(r'''
class A {
  A._constructor();
  A();
}
''', [
      error(HintCode.UNUSED_ELEMENT, 14, 12),
    ]);
  }

  test_constructor_notUsed_single() async {
    await assertNoErrorsInCode(r'''
class A {
  A._constructor();
}
''');
  }

  test_enum_isUsed_fieldReference() async {
    await assertNoErrorsInCode(r'''
enum _MyEnum {A}
main() {
  _MyEnum.A;
}
''');
  }

  test_enum_notUsed_noReference() async {
    await assertErrorsInCode(r'''
enum _MyEnum {A, B}
void f(d) {
  d.A;
  d.B;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 5, 7),
    ]);
  }

  test_factoryConstructor_notUsed_multiple() async {
    await assertErrorsInCode(r'''
class A {
  factory A._factory() => A();
  A();
}
''', [
      error(HintCode.UNUSED_ELEMENT, 22, 8),
    ]);
  }

  test_factoryConstructor_notUsed_single() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A._factory() => throw 0;
}
''');
  }

  test_fieldImplicitGetter_isUsed() async {
    await assertNoErrorsInCode(r'''
class A {
  int _g;
  int get g => this._g;
}
''');
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
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 1),
    ]);
  }

  test_functionLocal_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 2),
    ]);
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
''', [
      error(HintCode.UNUSED_ELEMENT, 0, 2),
    ]);
  }

  test_functionTop_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
_f(int p) {
  _f(p - 1);
}
main() {
}
''', [
      error(HintCode.UNUSED_ELEMENT, 0, 2),
    ]);
  }

  test_functionTop_notUsed_referenceInComment() async {
    await assertErrorsInCode(r'''
/// [_f] is a great function.
_f(int p) => 7;
''', [
      error(HintCode.UNUSED_ELEMENT, 30, 2),
    ]);
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
''', [
      error(HintCode.UNUSED_ELEMENT, 8, 2),
    ]);
  }

  test_getter_isUsed_invocation_deepSubclass() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String get _debugName;

  String toString() {
    return _debugName;
  }
}

class B extends A {
  @override
  String get _debugName => "B";
}

class C extends B {
  String get _debugName => "C";
}
''');
  }

  test_getter_isUsed_invocation_implicitThis() async {
    await assertErrorsInCode(r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
    ]);
  }

  test_getter_isUsed_invocation_parameterized() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  List<int> _list = List(1);
  int get _item => _list.first;
  set _item(int item) => _list[0] = item;
}
class B<T> {
  A<T> a;
}
void main() {
  B<int> b = B();
  b.a._item = 3;
  print(b.a._item == 7);
}
''');
  }

  test_getter_isUsed_invocation_parameterized_subclass() async {
    await assertNoErrorsInCode(r'''
abstract class A<T> {
  T get _defaultThing;
  T _thing;

  void main() {
    _thing ??= _defaultThing;
    print(_thing);
  }
}
class B extends A<int> {
  @override
  int get _defaultThing => 7;
}
''');
  }

  test_getter_isUsed_invocation_PrefixedIdentifier() async {
    await assertErrorsInCode(r'''
class A {
  get _g => null;
}
main(A a) {
  var v = a._g;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 48, 1),
    ]);
  }

  test_getter_isUsed_invocation_PropertyAccess() async {
    await assertErrorsInCode(r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
    ]);
  }

  test_getter_isUsed_invocation_subclass_plusPlus() async {
    await assertNoErrorsInCode(r'''
class A {
  int __a = 0;
  int get _a => __a;
  void set _a(int val) {
    __a = val;
  }
  int b() => _a++;
}
class B extends A {
  @override
  int get _a => 3;
}
''');
  }

  test_getter_notUsed_invocation_subclass() async {
    await assertErrorsInCode(r'''
class A {
  int __a = 0;
  int get _a => __a;
  void set _a(int val) {
    __a = val;
  }
  int b() => _a = 7;
}
class B extends A {
  @override
  int get _a => 3;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 35, 2),
      error(HintCode.UNUSED_ELEMENT, 155, 2),
    ]);
  }

  test_getter_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  get _g => null;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 2),
    ]);
  }

  test_getter_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
class A {
  get _g {
    return _g;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 2),
    ]);
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

  test_method_isUsed_invocation_fromMixinApplication() async {
    await assertNoErrorsInCode(r'''
mixin A {
  _m() {}
}
class C with A {
  useMethod() {
    _m();
  }
}
''');
  }

  test_method_isUsed_invocation_fromMixinWithConstraint() async {
    await assertNoErrorsInCode(r'''
class A {
  _m() {}
}
mixin M on A {
  useMethod() {
    _m();
  }
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

  test_method_isUsed_privateExtension() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  void m() {}
}
void main() {
  "hello".m();
}
''');
  }

  test_method_isUsed_privateExtension_binaryOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  int operator -(int other) => other;
}
void main() {
  "hello" - 3;
}
''');
  }

  test_method_isUsed_privateExtension_indexOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on bool {
  int operator [](int index) => 7;
}
void main() {
  false[3];
}
''');
  }

  test_method_isUsed_privateExtension_operator_assignment() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  String operator -(int other) => this;
}
void f(String s) {
  s -= 3;
}
''');
  }

  test_method_isUsed_privateExtension_postfixOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  String operator -(int i) => this;
}
void f(String a) {
  a--;
}
''');
  }

  // Postfix operators can only be called, not defined. The "notUsed" sibling to
  // this test is the test on a binary operator.
  test_method_isUsed_privateExtension_prefixOperator() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  int operator ~() => 7;
}
void main() {
  ~"hello";
}
''');
  }

  // Assignment operators can only be called, not defined. The "notUsed" sibling
  // to this test is the test on a binary operator.
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

  test_method_isUsed_unnamedExtension() async {
    await assertNoErrorsInCode(r'''
extension on String {
  void m() {}
}
void main() {
  "hello".m();
}
''');
  }

  test_method_isUsed_unnamedExtension_operator() async {
    await assertNoErrorsInCode(r'''
extension on String {
  int operator -(int other) => other;
}
void main() {
  "hello" - 3;
}
''');
  }

  test_method_notUsed_hasSameNameAsUsed() async {
    await assertErrorsInCode(r'''
class A {
  void _m1() {}
}
class B {
  void public() => _m1();
  void _m1() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 17, 3),
    ]);
  }

  test_method_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  static _m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 19, 2),
    ]);
  }

  test_method_notUsed_privateExtension() async {
    await assertErrorsInCode(r'''
extension _A on String {
  void m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 32, 1),
    ]);
  }

  test_method_notUsed_privateExtension_indexOperator() async {
    await assertErrorsInCode(r'''
extension _A on bool {
  int operator [](int index) => 7;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 38, 2),
    ]);
  }

  test_method_notUsed_privateExtension_operator() async {
    await assertErrorsInCode(r'''
extension _A on String {
  int operator -(int other) => other;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 40, 1),
    ]);
  }

  test_method_notUsed_privateExtension_prefixOperator() async {
    await assertErrorsInCode(r'''
extension _A on String {
  int operator ~() => 7;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 40, 1),
    ]);
  }

  test_method_notUsed_referenceFromItself() async {
    await assertErrorsInCode(r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 19, 2),
    ]);
  }

  test_method_notUsed_referenceInComment() async {
    await assertErrorsInCode(r'''
/// [A] has a method, [_f].
class A {
  int _f(int p) => 7;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 44, 2),
    ]);
  }

  test_method_notUsed_referenceInComment_outsideEnclosingClass() async {
    await assertErrorsInCode(r'''
class A {
  int _f(int p) => 7;
}
/// This is similar to [A._f].
int g() => 7;
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 2),
    ]);
  }

  test_method_notUsed_unnamedExtension() async {
    await assertErrorsInCode(r'''
extension on String {
  void m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 29, 1),
    ]);
  }

  test_method_notUsed_unnamedExtension_operator() async {
    await assertErrorsInCode(r'''
extension on String {
  int operator -(int other) => other;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 37, 1),
    ]);
  }

  test_publicStaticMethod_privateClass_isUsed() async {
    await assertNoErrorsInCode(r'''
class _A {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateClass_notUsed() async {
    await assertErrorsInCode(r'''
class _A {
  static void m() {}
}
void f(_A a) {}
''', [
      error(HintCode.UNUSED_ELEMENT, 25, 1),
    ]);
  }

  test_publicStaticMethod_privateExtension_isUsed() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateExtension_notUsed() async {
    await assertErrorsInCode(r'''
extension _A on String {
  static void m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 39, 1),
    ]);
  }

  test_publicStaticMethod_privateMixin_isUsed() async {
    await assertNoErrorsInCode(r'''
mixin _A {
  static void m() {}
}
void main() {
  _A.m();
}
''');
  }

  test_publicStaticMethod_privateMixin_notUsed() async {
    await assertErrorsInCode(r'''
mixin _A {
  static void m() {}
}
void main() {
  _A;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 25, 1),
    ]);
  }

  test_publicTopLevelFunction_notUsed() async {
    await assertNoErrorsInCode(r'''
int get a => 1;
''');
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
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 2),
    ]);
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
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 2),
    ]);
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
''', [
      error(HintCode.UNUSED_ELEMENT, 4, 2),
    ]);
  }

  test_topLevelVariable_notUsed_referenceInComment() async {
    await assertErrorsInCode(r'''
/// [_a] is a great variable.
int _a = 7;
''', [
      error(HintCode.UNUSED_ELEMENT, 34, 2),
    ]);
  }
}
