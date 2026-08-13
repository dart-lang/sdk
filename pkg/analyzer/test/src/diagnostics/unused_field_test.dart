// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedFieldTest extends PubPackageResolutionTest {
  test_isUsed_argument() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class Foo {}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 7;
}
''');
  }

  test_isUsed_extensionOnEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum Foo {a, b}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 1;
}
''');
  }

  test_isUsed_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int _f = 0;
}
class Bar with M {
  int g() => _f;
}
''');
  }

  test_isUsed_mixinRestriction() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  int _f = 0;
}
mixin M on Foo {
  int g() => _f;
}
''');
  }

  test_isUsed_parameterized_subclass() async {
    await resolveTestCodeWithDiagnostics(r'''
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

  test_isUsed_publicStaticField_privateClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension _A on String {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_reference_implicitThis() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
  main() {
    print(_f);
  }
}
print(x) {}
''');
  }

  test_isUsed_reference_implicitThis_expressionFunctionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
  m() => _f;
}
''');
  }

  test_isUsed_reference_implicitThis_subclass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f = 0;
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_propagatedElement() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_staticElement() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
}
main(a) {
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_underscoreField_shadowsLocal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var _ = 1;
  void m() {
    var _ = 0;
    print(_);
  }
}
''');
  }

  // See: https://github.com/dart-lang/sdk/issues/55862
  test_isUsed_underscoreField_shadowsParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var _ = 1;
  void m(int? _) {
    print(_);
  }
}
''');
  }

  test_notUsed_compoundAssign() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  main() {
    _f += 2;
  }
}
''');
  }

  test_notUsed_constructorFieldInitializers() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  A() : _f = 0;
}
''');
  }

  test_notUsed_extensionOnClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {}
extension Bar on Foo {
  static final _baz = 7;
//             ^^^^
// [diag.unusedField] The value of the field '_baz' isn't used.
}
''');
  }

  test_notUsed_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  A(this._f);
}
''');
  }

  test_notUsed_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
}
class Bar with M {}
''');
  }

  test_notUsed_mixinRestriction() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
}
mixin M on Foo {}
''');
  }

  test_notUsed_noReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
}
''');
  }

  test_notUsed_noReference_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _ = 0;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
}
''');
  }

  test_notUsed_noReference_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _ = 0;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
}
''');
  }

  test_notUsed_nullAssign() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  main() {
    _f++;
  }
}
''');
  }

  test_notUsed_prefixExpr() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  main() {
    ++_f;
  }
}
''');
  }

  test_notUsed_publicStaticField_privateClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class _A {
  static String f1 = "x";
//              ^^
// [diag.unusedField] The value of the field 'f1' isn't used.
}
void main() => print(_A);
''');
  }

  test_notUsed_publicStaticField_privateExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension _A on String {
  static String f1 = "x";
//              ^^
// [diag.unusedField] The value of the field 'f1' isn't used.
}
''');
  }

  test_notUsed_publicStaticField_privateMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin _A {
  static String f1 = "x";
//              ^^
// [diag.unusedField] The value of the field 'f1' isn't used.
}
void main() => print(_A);
''');
  }

  test_notUsed_referenceInComment() async {
    await resolveTestCodeWithDiagnostics(r'''
/// [A._f] is great.
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
}
''');
  }

  test_notUsed_simpleAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _f = 0;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
  m() {
    _f = 1;
  }
}
f(A a) {
  a._f = 2;
}
''');
  }

  test_privateEnum_publicConstant_isUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
}

void f() {
 _E.v;
}
''');
  }

  test_privateEnum_publicConstant_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
//^
// [diag.unusedField] The value of the field 'v' isn't used.
}

void f() {
  _E;
}
''');
  }

  test_privateEnum_publicInstanceField_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
  final int foo = 0;
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_publicStaticField_isUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
  static final int foo = 0;
}

void f() {
  _E.v;
  _E.foo;
}
''');
  }

  test_privateEnum_publicStaticField_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.unusedField] The value of the field 'foo' isn't used.
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_values_isUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v
}

void f() {
  _E.values;
}
''');
  }

  test_privateEnum_values_isUsed_hasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum _E {
  v;
  set foo(int _) {}
}

void f() {
  _E.values;
}
''');
  }

  test_publicEnum_privateConstant_isUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  _v
}

void f() {
  E._v;
}
''');
  }

  test_publicEnum_privateConstant_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  _v
//^^
// [diag.unusedField] The value of the field '_v' isn't used.
}
''');
  }

  test_publicEnum_privateInstanceField_isUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int _foo = 0;
}

void f() {
  E.v._foo;
}
''');
  }

  test_publicEnum_privateInstanceField_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int _foo = 0;
//          ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
}
''');
  }
}
