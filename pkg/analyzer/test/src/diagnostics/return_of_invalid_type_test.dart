// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeTest);
    defineReflectiveTests(ReturnOfInvalidTypeWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeTest extends PubPackageResolutionTest {
  test_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Td = int Function();
Td f() {
  return () => "hello";
//             ^^^^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'String' isn't returnable from a 'int' function, as required by the closure's context.
}
''');
  }

  test_factoryConstructor_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C.named() => 7;
//                     ^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'int' can't be returned from the constructor 'C.named' because it has a return type of 'C'.
}
''');
  }

  test_factoryConstructor_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C() => 7;
//               ^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'int' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');
  }

  test_function_async_block__to_Future_void() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void> f1() async {}
Future<void> f2() async { return; }
Future<void> f3() async { return null; }
Future<void> f4() async { return g1(); }
Future<void> f5() async { return g2(); }
g1() {}
void g2() {}
''');
  }

  test_function_async_block_Future_Future_int__to_Future_int() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f(Future<Future<int>> a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Future<Future<int>>' can't be returned from the function 'f' because it has a return type of 'Future<int>'.
}
''');
  }

  test_function_async_block_Future_String__to_Future_int() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f(Future<String> a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Future<String>' can't be returned from the function 'f' because it has a return type of 'Future<int>'.
}
''');
  }

  test_function_async_block_Future_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f1(Future<void> a) async { return a; }
dynamic f2(Future<void> a) async { return a; }
''');
  }

  test_function_async_block_illegalReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() async {
// [diag.illegalAsyncReturnType][column 1][length 3] Functions marked 'async' must have a return type which is a supertype of 'Future'.
  return 5;
}
''');
  }

  test_function_async_block_int__to_Future_int() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f() async {
  return 0;
}
''');
  }

  test_function_async_block_int__to_Future_num() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<num> f() async {
  return 0;
}
''');
  }

  test_function_async_block_int__to_Future_String() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<String> f() async {
  return 5;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of 'Future<String>'.
}
''');
  }

  test_function_async_block_int__to_Future_void() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void> f() async {
  return 0;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of 'Future<void>'.
}
''');
  }

  test_function_async_block_int__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() async {
  return 5;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of 'void'.
}
''');
  }

  test_function_async_block_void__to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f(void a) async {
  return a;
}
''');
  }

  test_function_async_block_void__to_Future_int() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f(void a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'Future<int>'.
}
''');
  }

  test_function_async_block_void__to_Future_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<Null> f(void a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'Future<Null>'.
}
''');
  }

  test_function_async_block_void__to_FutureOr_ObjectQ() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

FutureOr<Object?> f(void a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'FutureOr<Object?>'.
}
''');
  }

  test_function_async_block_void__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void a) async {
  return a;
}
''');
  }

  test_function_async_expression_dynamic__to_Future_int() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f(dynamic a) async => a;
''');
  }

  test_function_asyncStar() async {
    // RETURN_OF_INVALID_TYPE shouldn't be reported in addition to this error.
    await resolveTestCodeWithDiagnostics(r'''
Stream<int> f() async* => 3;
//                     ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  test_function_sync_block__invalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  return new X();
//           ^
// [diag.newWithNonType] The name 'X' isn't a class.
}
''');
  }

  test_function_sync_block__to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
    return 0;
  } on ArgumentError {
    return 'abc';
  }
}
''');
  }

  test_function_sync_block__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
g1() {}
void g2() {}
''');
  }

  test_function_sync_block_genericFunction__to_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
U Function<U>(U) foo(T Function<T>(T a) f) {
  return f;
}
''');
  }

  test_function_sync_block_genericFunction__to_genericFunction_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
U Function<U>(U, int) foo(T Function<T>(T a) f) {
  return f;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'T Function<T>(T)' can't be returned from the function 'foo' because it has a return type of 'U Function<U>(U, int)'.
}
''');
  }

  test_function_sync_block_genericFunction__to_nonGenericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
int Function(int) foo(T Function<T>(T a) f) {
  return f;
}
''');
  }

  test_function_sync_block_genericFunction__to_nonGenericFunction_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
int Function(int, int) foo(T Function<T>(T a) f) {
  return f;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'dynamic Function(dynamic)' can't be returned from the function 'foo' because it has a return type of 'int Function(int, int)'.
}
''');
  }

  test_function_sync_block_int__to_num() async {
    await resolveTestCodeWithDiagnostics(r'''
num f(int a) {
  return a;
}
''');
  }

  test_function_sync_block_int__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  return 42;
//       ^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of 'void'.
}
''');
  }

  test_function_sync_block_num__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int f(num a) {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'num' can't be returned from the function 'f' because it has a return type of 'int'.
}
''');
  }

  test_function_sync_block_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() {
  return '0';
//       ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of 'int'.
}
''');
  }

  test_function_sync_block_typeParameter__to_Type() async {
    // https://code.google.com/p/dart/issues/detail?id=18468
    //
    // This test verifies that the type of T is more specific than Type, where T
    // is a type parameter and Type is the type Type from core, this particular
    // test case comes from issue 18468.
    //
    // A test cannot be added to TypeParameterTypeImplTest since the types
    // returned out of the TestTypeProvider don't have a mock 'dart.core'
    // enclosing library element.
    // See TypeParameterTypeImpl.isMoreSpecificThan().
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T> {
  Type get t => T;
}
''');
  }

  test_function_sync_block_void__to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f(void a) {
  return a;
}
''');
  }

  test_function_sync_block_void__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int f(void a) {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'int'.
}
''');
  }

  test_function_sync_block_void__to_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
Null f(void a) {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'Null'.
}
''');
  }

  test_function_sync_block_void__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void a) {
  return a;
}
''');
  }

  test_function_sync_expression_genericFunction__to_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
U Function<U>(U) foo(T Function<T>(T a) f) => f;
''');
  }

  test_function_sync_expression_genericFunction__to_genericFunction_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
U Function<U>(U, int) foo(T Function<T>(T a) f) => f;
//                                                 ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'T Function<T>(T)' can't be returned from the function 'foo' because it has a return type of 'U Function<U>(U, int)'.
''');
  }

  test_function_sync_expression_genericFunction__to_nonGenericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
int Function(int) foo(T Function<T>(T a) f) => f;
''');
  }

  test_function_sync_expression_genericFunction__to_nonGenericFunction_notAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
int Function(int, int) foo(T Function<T>(T a) f) => f;
//                                                  ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'dynamic Function(dynamic)' can't be returned from the function 'foo' because it has a return type of 'int Function(int, int)'.
''');
  }

  test_function_sync_expression_int__to_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() => 42;
''');
  }

  test_function_sync_expression_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() => '0';
//         ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of 'int'.
''');
  }

  test_function_syncStar() async {
    // RETURN_OF_INVALID_TYPE shouldn't be reported in addition to this error.
    await resolveTestCodeWithDiagnostics(r'''
Iterable<int> f() sync* => 3;
//                      ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  test_functionExpression_async_futureOr_void__to_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
void a = null;

Object Function() f = () async {
  return a;
};
''');
  }

  test_functionExpression_async_futureQ_void__to_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void>? a = (throw 0);

Object Function() f = () async {
  return a;
};
''');
  }

  test_functionExpression_async_void__to_FutureOr_ObjectQ() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void a = (throw 0);

FutureOr<Object?> Function() f = () async {
  return a;
};
''');
  }

  test_getter_sync_block_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int get g {
  return '0';
//       ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'g' because it has a return type of 'int'.
}
''');
  }

  test_getter_sync_expression_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
int get g => '0';
//           ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'g' because it has a return type of 'int'.
''');
  }

  test_localFunction_sync_block_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int g() {
    return '0';
//         ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'g' because it has a return type of 'int'.
  }
  g();
}
''');
  }

  test_localFunction_sync_expression_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m() {
    int f() => '0';
//             ^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of 'int'.
    f();
  }
}
''');
  }

  test_method_async_block_callable_class() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Fn = void Function(String s);

class CanFn {
  void call(String s) => print(s);
}

Future<Fn> f() async {
  return CanFn();
}
''');
  }

  test_method_sync_block_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int m() {
    return '0';
//         ^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'String' can't be returned from the method 'm' because it has a return type of 'int'.
  }
}
''');
  }

  test_method_sync_expression_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class F<T>  {
  T get value;
}

abstract class G<U> {
  U test(F<U> arg) => arg.value;
}
''');
  }

  test_method_sync_expression_String__to_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int f() => '0';
//           ^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'String' can't be returned from the method 'f' because it has a return type of 'int'.
}
''');
  }
}

@reflectiveTest
class ReturnOfInvalidTypeWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_return() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
int f(dynamic a) => a;
//                  ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'dynamic' can't be returned from the function 'f' because it has a return type of 'int'.
''');
  }

  test_return_async() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
Future<int> f(dynamic a) async {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'dynamic' can't be returned from the function 'f' because it has a return type of 'Future<int>'.
}
''');
  }
}
