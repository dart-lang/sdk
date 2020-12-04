// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentTypeNotAssignableTest);
    defineReflectiveTests(ArgumentTypeNotAssignableWithNullSafetyTest);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableTest extends PubPackageResolutionTest {
  test_ambiguousClassName() async {
    // See dartbug.com/19624
    newFile('$testPackageLibPath/lib2.dart', content: '''
class _A {}
g(h(_A a)) {}''');
    await assertErrorsInCode('''
import 'lib2.dart';
class _A {}
f() {
  g((_A a) {});
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 9),
    ]);
    // The name _A is private to the library it's defined in, so this is a type
    // mismatch. Furthermore, the error message should mention both _A and the
    // filenames so the user can figure out what's going on.
    String message = result.errors[0].message;
    expect(message.contains("_A"), isTrue);
  }

  test_annotation_namedConstructor() async {
    await assertErrorsInCode('''
class A {
  const A.fromInt(int p);
}
@A.fromInt('0')
main() {
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 49, 3),
    ]);
  }

  test_annotation_unnamedConstructor() async {
    await assertErrorsInCode('''
class A {
  const A(int p);
}
@A('0')
main() {
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 33, 3),
    ]);
  }

  test_binary() async {
    await assertErrorsInCode('''
class A {
  operator +(int p) {}
}
f(A a) {
  a + '0';
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 50, 3),
    ]);
  }

  test_call() async {
    await assertErrorsInCode('''
typedef bool Predicate<T>(T object);

Predicate<String> f() => (String s) => false;

void main() {
  f().call(3);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 110, 1),
    ]);
  }

  test_cascadeSecond() async {
    await assertErrorsInCode('''
// filler filler filler filler filler filler filler filler filler filler
class A {
  B ma() { return new B(); }
}
class B {
  mb(String p) {}
}

main() {
  A a = new A();
  a..  ma().mb(0);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 186, 1),
    ]);
  }

  test_const() async {
    await assertErrorsInCode('''
class A {
  const A(String p);
}
main() {
  const A(42);
}''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 52, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 2),
    ]);
  }

  test_const_super() async {
    await assertErrorsInCode('''
class A {
  const A(String p);
}
class B extends A {
  const B() : super(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 73, 2),
    ]);
  }

  test_for_element_type_inferred_from_rewritten_node() async {
    // See https://github.com/dart-lang/sdk/issues/39171
    await assertNoErrorsInCode('''
void f<T>(Iterable<T> Function() g, int Function(T) h) {
  [for (var x in g()) if (x is String) h(x)];
}
''');
  }

  test_for_statement_type_inferred_from_rewritten_node() async {
    // See https://github.com/dart-lang/sdk/issues/39171
    await assertNoErrorsInCode('''
void f<T>(Iterable<T> Function() g, void Function(T) h) {
  for (var x in g()) {
    if (x is String) {
      h(x);
    }
  }
}
''');
  }

  test_functionExpressionInvocation_required() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ('');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
  }

  test_functionType() async {
    await assertErrorsInCode(r'''
m() {
  var a = new A();
  a.n(() => 0);
}
class A {
  n(void f(int i)) {}
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 7),
    ]);
  }

  test_index_invalidRead() async {
    await assertErrorsInCode('''
class A {
  int operator [](int index) => 0;
}
f(A a) {
  a['0'];
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 60, 3),
    ]);
  }

  test_index_invalidRead_validWrite() async {
    await assertErrorsInCode('''
class A {
  int operator [](int index) => 0;
  operator []=(String index, int value) {}
}
f(A a) {
  a['0'] += 0;
  ++a['0'];
  a['0']++;
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 103, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 120, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 130, 3),
    ]);
  }

  test_index_invalidWrite() async {
    await assertErrorsInCode('''
class A {
  operator []=(int index, int value) {}
}
f(A a) {
  a['0'] = 0;
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 65, 3),
    ]);
  }

  test_index_validRead_invalidWrite() async {
    await assertErrorsInCode('''
class A {
  int operator [](String index) => 0;
  operator []=(int index, int value) {}
}
f(A a) {
  a['0'] += 0;
  ++a['0'];
  a['0']++;
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 103, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 120, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 130, 3),
    ]);
  }

  test_interfaceType() async {
    await assertErrorsInCode(r'''
m() {
  var i = '';
  n(i);
}
n(int i) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 24, 1),
    ]);
  }

  test_invocation_callParameter() async {
    await assertErrorsInCode('''
class A {
  call(int p) {}
}
f(A a) {
  a('0');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 3),
    ]);
  }

  test_invocation_callVariable() async {
    await assertErrorsInCode('''
class A {
  call(int p) {}
}
main() {
  A a = new A();
  a('0');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 59, 3),
    ]);
  }

  test_invocation_functionParameter() async {
    await assertErrorsInCode('''
a(b(int p)) {
  b('0');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 18, 3),
    ]);
  }

  test_invocation_functionParameter_generic() async {
    await assertErrorsInCode('''
class A<K, V> {
  m(f(K k), V v) {
    f(v);
  }
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 41, 1),
    ]);
  }

  test_invocation_functionTypes_optional() async {
    await assertErrorsInCode('''
void acceptFunOptBool(void funNumOptBool([bool b])) {}
void funBool(bool b) {}
main() {
  acceptFunOptBool(funBool);
}''', [
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 107, 7),
    ]);
  }

  test_invocation_functionTypes_optional_method() async {
    await assertErrorsInCode('''
void acceptFunOptBool(void funOptBool([bool b])) {}
class C {
  static void funBool(bool b) {}
}
main() {
  acceptFunOptBool(C.funBool);
}''', [
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 125, 9),
    ]);
  }

  test_invocation_generic() async {
    await assertErrorsInCode('''
class A<T> {
  m(T t) {}
}
f(A<String> a) {
  a.m(1);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_invocation_named() async {
    await assertErrorsInCode('''
f({String p = ''}) {}
main() {
  f(p: 42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 35, 5),
    ]);
  }

  test_invocation_optional() async {
    await assertErrorsInCode('''
f([String p = '']) {}
main() {
  f(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 35, 2),
    ]);
  }

  test_invocation_required() async {
    await assertErrorsInCode('''
f(String p) {}
main() {
  f(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 28, 2),
    ]);
  }

  test_invocation_typedef_generic() async {
    await assertErrorsInCode('''
typedef A<T>(T p);
f(A<int> a) {
  a('1');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 37, 3),
    ]);
  }

  test_invocation_typedef_local() async {
    await assertErrorsInCode('''
typedef A(int p);
A getA() => throw '';
main() {
  A a = getA();
  a('1');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 69, 3),
    ]);
  }

  test_invocation_typedef_parameter() async {
    await assertErrorsInCode('''
typedef A(int p);
f(A a) {
  a('1');
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 3),
    ]);
  }

  test_new_generic() async {
    await assertErrorsInCode('''
class A<T> {
  A(T p) {}
}
main() {
  new A<String>(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 2),
    ]);
  }

  test_new_optional() async {
    await assertErrorsInCode('''
class A {
  A([String p = '']) {}
}
main() {
  new A(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 53, 2),
    ]);
  }

  test_new_required() async {
    await assertErrorsInCode('''
class A {
  A(String p) {}
}
main() {
  new A(42);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 46, 2),
    ]);
  }

  @failingTest
  test_tearOff_required() async {
    await assertErrorsInCode('''
class C {
  Object/*=T*/ f/*<T>*/(Object/*=T*/ x) => x;
}
g(C c) {
  var h = c.f/*<int>*/;
  print(h('s'));
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 99, 1),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableWithNullSafetyTest
    extends ArgumentTypeNotAssignableTest with WithNullSafetyMixin {
  test_binary_eqEq_covariantParameterType() async {
    await assertErrorsInCode(r'''
class A {
  bool operator==(covariant A other) => false;
}

void f(A a, A? aq) {
  a == 0;
  aq == 1;
  aq == aq;
  aq == null;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 88, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 99, 1),
    ]);
  }

  test_downcast() async {
    await assertErrorsInCode(r'''
m() {
  num y = 1;
  n(y);
}
n(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 23, 1),
    ]);
  }

  @failingTest
  test_downcast_nullableNonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int? y;
  n(y);
}
n(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 24, 1),
    ]);
  }

  test_dynamicCast() async {
    await assertNoErrorsInCode(r'''
m() {
  dynamic i;
  n(i);
}
n(int i) {}
''');
  }

  @failingTest
  @override
  test_invocation_functionTypes_optional() async {
    // The test is currently generating an error where none is expected.
    await super.test_invocation_functionTypes_optional();
  }

  @override
  test_invocation_functionTypes_optional_method() async {
    await assertErrorsInCode('''
void acceptFunOptBool(void funOptBool([bool b])) {}
class C {
  static void funBool(bool b) {}
}
main() {
  acceptFunOptBool(C.funBool);
}''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 125, 9),
    ]);
  }
}
