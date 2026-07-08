// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentTypeNotAssignableTest);
    defineReflectiveTests(ArgumentTypeNotAssignableWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableTest extends PubPackageResolutionTest {
  test_ambiguousClassName() async {
    // See dartbug.com/19624
    newFile('$testPackageLibPath/lib2.dart', '''
class _A {}
g(h(_A a)) {}''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart';
class _A {}
f() {
  g((_A a) {});
//  ^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null Function(_A)' can't be assigned to the parameter type 'dynamic Function(_A)'.
}''');
    // The name _A is private to the library it's defined in, so this is a type
    // mismatch. Furthermore, the error message should mention both _A and the
    // filenames so the user can figure out what's going on.
    String message = result.diagnostics[0].message;
    expect(message.contains("_A"), isTrue);
  }

  test_annotation_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const A(String _) {}

@A(0)
// ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
void f() {}
''');
  }

  test_annotation_namedConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.fromInt(int p);
}
@A.fromInt('0')
//         ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
main() {}
''');
  }

  test_annotation_namedConstructor_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A.fromInt(T p);
}
@A<int>.fromInt('0')
//              ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
main() {
}''');
  }

  test_annotation_type_arguments_inferred() async {
    await resolveTestCodeWithDiagnostics(r'''
@C([])
int i = 0;

class C<T> {
  const C(List<List<T>> arg);
}
''');
  }

  test_annotation_unnamedConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
@A('0')
// ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
main() {
}''');
  }

  test_binary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +(int p) {}
}
f(A a) {
  a + '0';
//    ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_binary_eqEq_covariantParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator==(covariant A other) => false;
}

void f(A a, A? aq) {
  a == 0;
//     ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'A?'.
  aq == 1;
//      ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'A?'.
  aq == aq;
  aq == null;
}
''');
  }

  test_call() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef bool Predicate<T>(T object);

Predicate<String> f() => (String s) => false;

void main() {
  f().call(3);
//         ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_cascadeSecond() async {
    await resolveTestCodeWithDiagnostics(r'''
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
//             ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(String p);
}
main() {
  const A(42);
//        ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
// [diag.constConstructorParamTypeMismatch] A value of type 'int' can't be assigned to a parameter of type 'String' in a const constructor.
}''');
  }

  test_const_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(String p);
}
class B extends A {
  const B() : super(42);
//                  ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_downcast() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  num y = 1;
  n(y);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}
n(int x) {}
''');
  }

  test_downcast_nullableNonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? y;
  n(y);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'int?' can't be assigned to the parameter type 'int'.
}
n(int x) {}
''');
  }

  test_dynamicCast() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  dynamic i;
  n(i);
}
n(int i) {}
''');
  }

  test_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
// [diag.constConstructorParamTypeMismatch] A value of type 'int' can't be assigned to a parameter of type 'String' in a const constructor.
  const E(String a);
}
''');
  }

  test_enumConstant_implicitDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(double a);
}
''');
  }

  test_expressionFromConstructorTearoff_withoutTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

var g = C.new;
var x = g('Hello');
''');
  }

  test_expressionFromConstructorTearoff_withTypeArgs_assignable() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

var g = C<int>.new;
var x = g(0);
''');
  }

  test_expressionFromConstructorTearoff_withTypeArgs_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

var g = C<int>.new;
var x = g('Hello');
//        ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_expressionFromFunctionTearoff_withoutTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

var g = f;
var x = g('Hello');
''');
  }

  test_expressionFromFunctionTearoff_withTypeArgs_assignable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

var g = f<int>;
var x = g(0);
''');
  }

  test_expressionFromFunctionTearoff_withTypeArgs_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

var g = f<int>;
var x = g('Hello');
//        ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
''');
  }

  test_for_element_type_inferred_from_rewritten_node() async {
    // See https://github.com/dart-lang/sdk/issues/39171
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(Iterable<T> Function() g, int Function(T) h) {
  [for (var x in g()) if (x is String) h(x)];
}
''');
  }

  test_for_statement_type_inferred_from_rewritten_node() async {
    // See https://github.com/dart-lang/sdk/issues/39171
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (int x) {} ('');
//            ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  var a = new A();
  a.n(() => 0);
//    ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'void Function()' can't be assigned to the parameter type 'void Function(int)'.
}
class A {
  n(void f(int i)) {}
}
''');
  }

  test_implicitCallReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int p) {}
}
void f(void Function(int) a) {}
void g(A a) {
  f(a);
}
''');
  }

  test_implicitCallReference_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int p) {}
}
void defaultFunc(int p) {}
void f({void Function(int) a = defaultFunc}) {}
void g(A a) {
  f(a: a);
}
''');
  }

  test_implicitCallReference_namedAndRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int p) {}
}
void f({required void Function(int) a}) {}
void g(A a) {
  f(a: a);
}
''');
  }

  test_implicitCallReference_this() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int p) {}

  void f(void Function(int) a) {}
  void g() {
    f(this);
  }
}
''');
  }

  test_index_invalidRead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
}
f(A a) {
  a['0'];
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_index_invalidRead_validWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
  operator []=(String index, int value) {}
}
f(A a) {
  a['0'] += 0;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  ++a['0'];
//    ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  a['0']++;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_index_invalidWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(int index, int value) {}
}
f(A a) {
  a['0'] = 0;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_index_validRead_invalidWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](String index) => 0;
  operator []=(int index, int value) {}
}
f(A a) {
  a['0'] += 0;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  ++a['0'];
//    ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  a['0']++;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  var i = '';
  n(i);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
n(int i) {}
''');
  }

  test_invocation_callParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  call(int p) {}
}
f(A a) {
  a('0');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_invocation_callVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  call(int p) {}
}
main() {
  A a = new A();
  a('0');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_invocation_functionParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
a(b(int p)) {
  b('0');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_invocation_functionParameter_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V> {
  m(f(K k), V v) {
    f(v);
//    ^
// [diag.argumentTypeNotAssignable] The argument type 'V' can't be assigned to the parameter type 'K'.
  }
}''');
  }

  test_invocation_functionTypes_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
void acceptFunOptBool(void funNumOptBool([bool b])) {}
void funBool(bool b) {}
main() {
  acceptFunOptBool(funBool);
//                 ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'void Function(bool)' can't be assigned to the parameter type 'void Function([bool])'.
}''');
  }

  test_invocation_functionTypes_optional_method() async {
    await resolveTestCodeWithDiagnostics(r'''
void acceptFunOptBool(void funOptBool([bool b])) {}
class C {
  static void funBool(bool b) {}
}
main() {
  acceptFunOptBool(C.funBool);
//                 ^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'void Function(bool)' can't be assigned to the parameter type 'void Function([bool])'.
}''');
  }

  test_invocation_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  m(T t) {}
}
f(A<String> a) {
  a.m(1);
//    ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_invocation_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f({String p = ''}) {}
main() {
  f(p: 42);
//     ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_invocation_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
f([String p = '']) {}
main() {
  f(42);
//  ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_invocation_required() async {
    await resolveTestCodeWithDiagnostics(r'''
f(String p) {}
main() {
  f(42);
//  ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_invocation_typedef_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T>(T p);
f(A<int> a) {
  a('1');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_invocation_typedef_local() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A(int p);
A getA() => throw '';
main() {
  A a = getA();
  a('1');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_invocation_typedef_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A(int p);
f(A a) {
  a('1');
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}''');
  }

  test_map_indexGet() async {
    // Any type may be passed to Map.operator[].
    await resolveTestCodeWithDiagnostics(r'''
main() {
  Map<int, int> m = <int, int>{};
  m['x'];
}
''');
  }

  test_map_indexSet() async {
    // The type passed to Map.operator[]= must match the key type.
    await resolveTestCodeWithDiagnostics(r'''
main() {
  Map<int, int> m = <int, int>{};
  m['x'] = 0;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
''');
  }

  test_map_indexSet_ifNull() async {
    // The type passed to Map.operator[]= must match the key type.
    await resolveTestCodeWithDiagnostics(r'''
main() {
  Map<int, int> m = <int, int>{};
  m['x'] ??= 0;
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
''');
  }

  test_new_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A(T p) {}
}
main() {
  new A<String>(42);
//              ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_new_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([String p = '']) {}
}
main() {
  new A(42);
//      ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  test_new_required() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(String p) {}
}
main() {
  new A(42);
//      ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}''');
  }

  void test_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, int b) r) {}

void g() {
  f((a: 1, b: 2));
//  ^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type '({int a, int b})' can't be assigned to the parameter type '(int, int)'. Expected 2 positional arguments, but got 0 instead.
}
''');
  }

  void test_recordType_namedArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = ({
  int b,
  int c,
});

void f(A a){print(a);}

main() {
 f((bb:2, c:3));
// ^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type '({int bb, int c})' can't be assigned to the parameter type 'A'. Unexpected named argument `bb` with type `int`.
}
''');
  }

  void test_recordType_namedArguments_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = ({
  int b,
  int c,
});

void f(A a){print(a);}

main() {
 f((b:2));
// ^^^^^
// [diag.argumentTypeNotAssignable] The argument type '({int b})' can't be assigned to the parameter type 'A'. Expected 2 named arguments, but got 1 instead.
}
''');
  }

  void test_recordType_positionalArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = (
  int b,
  int c,
);

void f(A a){print(a);}

main() {
 f((3, 2, 1));
// ^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type '(int, int, int)' can't be assigned to the parameter type 'A'. Expected 2 positional arguments, but got 3 instead.
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_extensionTypePrimaryConstructor() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
extension type E(int i) {}

dynamic a;
var e = E(a);
//        ^
// [diag.argumentTypeNotAssignable] The argument type 'dynamic' can't be assigned to the parameter type 'int'.
''');
  }

  test_functionCall() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(int i) {}
void foo(dynamic a) {
  f(a);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'dynamic' can't be assigned to the parameter type 'int'.
}
''');
  }

  test_operator() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void foo(int i, dynamic a) {
  i + a;
//    ^
// [diag.argumentTypeNotAssignable] The argument type 'dynamic' can't be assigned to the parameter type 'num'.
}
''');
  }
}
