// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldTest);
  });
}

@reflectiveTest
class UnusedFieldTest extends PubPackageResolutionTest {
  @override
  bool get enableUnusedElement => true;

  test_isUsed_argument() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    print(++_f);
  }
}
print(x) {}
''');
  }

  test_isUsed_extensionOnClass() async {
    await assertNoErrorsInCode(r'''
class Foo {}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 7;
}
''');
  }

  test_isUsed_extensionOnEnum() async {
    await assertNoErrorsInCode(r'''
enum Foo {a, b}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 1;
}
''');
  }

  test_isUsed_mixin() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int _f = 0;
}
class Bar with M {
  int g() => _f;
}
''');
  }

  test_isUsed_mixinRestriction() async {
    await assertNoErrorsInCode(r'''
class Foo {
  int _f = 0;
}
mixin M on Foo {
  int g() => _f;
}
''');
  }

  test_isUsed_parameterized_subclass() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {
  T _f;
  A._(this._f);
}
class B extends A<int> {
  B._(int f) : super._(f);
}
void main() {
  B b = B._(7);
  print(b._f == 7);
}
''');
  }

  test_isUsed_privateEnum_publicValue() async {
    await assertNoErrorsInCode(r'''
enum _Foo {a, b}
f() => print('${_Foo.a}${_Foo.b}');
''');
  }

  test_isUsed_privateEnum_values() async {
    await assertNoErrorsInCode(r'''
enum _Foo {a}
f() => _Foo.values;
''');
  }

  test_isUsed_publicEnum_privateValue() async {
    await assertNoErrorsInCode(r'''
enum Foo {_a, _b}
f() => print('${Foo._a}${Foo._b}');
''');
  }

  test_isUsed_publicStaticField_privateClass() async {
    await assertNoErrorsInCode(r'''
class _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateExtension() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateMixin() async {
    await assertNoErrorsInCode(r'''
mixin _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_reference_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
print(x) {}
''');
  }

  test_isUsed_reference_implicitThis_expressionFunctionBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  m() => _f;
}
''');
  }

  test_isUsed_reference_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f;
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_propagatedElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_staticElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_unresolved() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main(a) {
  print(a._f);
}
print(x) {}
''');
  }

  test_notUsed_compoundAssign() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  main() {
    _f += 2;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_constructorFieldInitializers() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A() : _f = 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_extensionOnClass() async {
    await assertErrorsInCode(r'''
class Foo {}
extension Bar on Foo {
  static final _baz = 7;
}
''', [
      error(HintCode.UNUSED_FIELD, 51, 4),
    ]);
  }

  test_notUsed_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A(this._f);
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  int _f = 0;
}
class Bar with M {}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_mixinRestriction() async {
    await assertErrorsInCode(r'''
class Foo {
  int _f = 0;
}
mixin M on Foo {}
''', [
      error(HintCode.UNUSED_FIELD, 18, 2),
    ]);
  }

  test_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_nullAssign() async {
    await assertNoErrorsInCode(r'''
class A {
  var _f;
  m() {
    _f ??= doSomething();
  }
}
doSomething() => 0;
''');
  }

  test_notUsed_postfixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    _f++;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_prefixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    ++_f;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_privateEnum_publicValue() async {
    await assertErrorsInCode(r'''
enum _Foo {a}
f() => _Foo;
''', [
      error(HintCode.UNUSED_FIELD, 11, 1),
    ]);
  }

  test_notUsed_publicEnum_privateValue() async {
    await assertErrorsInCode(r'''
enum Foo {_a}
''', [
      error(HintCode.UNUSED_FIELD, 10, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateClass() async {
    await assertErrorsInCode(r'''
class _A {
  static String f1 = "x";
}
void main() => print(_A);
''', [
      error(HintCode.UNUSED_FIELD, 27, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateExtension() async {
    await assertErrorsInCode(r'''
extension _A on String {
  static String f1 = "x";
}
''', [
      error(HintCode.UNUSED_FIELD, 41, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateMixin() async {
    await assertErrorsInCode(r'''
mixin _A {
  static String f1 = "x";
}
void main() => print(_A);
''', [
      error(HintCode.UNUSED_FIELD, 27, 2),
    ]);
  }

  test_notUsed_referenceInComment() async {
    await assertErrorsInCode(r'''
/// [A._f] is great.
class A {
  int _f;
}
''', [
      error(HintCode.UNUSED_FIELD, 37, 2),
    ]);
  }

  test_notUsed_simpleAssignment() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  m() {
    _f = 1;
  }
}
main(A a) {
  a._f = 2;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }
}
