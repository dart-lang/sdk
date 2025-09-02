// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFunctionTearoffTest);
    defineReflectiveTests(CreateFunctionTest);
  });
}

@reflectiveTest
class CreateFunctionTearoffTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FUNCTION_TEAROFF;

  Future<void> test_assignment() async {
    await resolveTestCode('''
bool Function() f = g;
''');
    await assertHasFix('''
bool Function() f = g;

bool g() {
}
''');
  }

  Future<void> test_functionType_cascadeSecond() async {
    await resolveTestCode('''
class A {
  B ma() => throw 0;
}
class B {
  useFunction(int g(double a, String b)) {}
}

void f() {
  A a = new A();
  a..ma().useFunction(test);
}
''');
    await assertHasFix('''
class A {
  B ma() => throw 0;
}
class B {
  useFunction(int g(double a, String b)) {}
}

void f() {
  A a = new A();
  a..ma().useFunction(test);
}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_coreFunction() async {
    await resolveTestCode('''
void f() {
  useFunction(g: test);
}
useFunction({Function? g}) {}
''');
    await assertHasFix('''
void f() {
  useFunction(g: test);
}
useFunction({Function? g}) {}

test() {
}
''');
  }

  Future<void> test_functionType_dynamicArgument() async {
    await resolveTestCode('''
void f() {
  useFunction(test);
}
useFunction(int g(a, b)) {}
''');
    await assertHasFix('''
void f() {
  useFunction(test);
}
useFunction(int g(a, b)) {}

int test(a, b) {
}
''');
  }

  Future<void> test_functionType_function() async {
    await resolveTestCode('''
void f() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
void f() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_function_namedArgument() async {
    await resolveTestCode('''
void f() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)?}) {}
''');
    await assertHasFix('''
void f() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)?}) {}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_FunctionCall() async {
    await resolveTestCode('''
void f1(int i) {
  f2(f3);
}

void f2(int Function() f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(f3);
}

void f2(int Function() f) {}

int f3() {
}
''');
  }

  Future<void> test_functionType_importType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

useFunction(int g(A a)) {}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

void f() {
  useFunction(test);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

void f() {
  useFunction(test);
}

int test(A a) {
}
''');
  }

  Future<void> test_functionType_inside_conditional_operator() async {
    await resolveTestCode('''
void f1(int i) {
  f2(i == 0 ? f3 : (v) => v);
}

void f2(int Function(int) f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(i == 0 ? f3 : (v) => v);
}

void f2(int Function(int) f) {}

int f3(int p1) {
}
''');
  }

  Future<void> test_functionType_inside_conditional_operator_else() async {
    await resolveTestCode('''
void f1(int i) {
  f2(i == 0 ? (v) => v : f3);
}

void f2(int Function(int) f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(i == 0 ? (v) => v : f3);
}

void f2(int Function(int) f) {}

int f3(int p1) {
}
''');
  }

  Future<void> test_functionType_inside_record_functionType() async {
    await resolveTestCode('''
void f1(int i) {
  f2((0, f3));
}

void f2((int, int Function(int)) f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2((0, f3));
}

void f2((int, int Function(int)) f) {}

int f3(int p1) {
}
''');
  }

  Future<void> test_functionType_inside_record_functionType_named() async {
    await resolveTestCode('''
void f1(int i) {
  f2((f: f3));
}

void f2(({int Function(int) f}) f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2((f: f3));
}

void f2(({int Function(int) f}) f) {}

int f3(int p1) {
}
''');
  }

  Future<void> test_record_tearoff() async {
    await resolveTestCode('''
(bool Function(),) f = (g,);
''');
    await assertHasFix('''
(bool Function(),) f = (g,);

bool g() {
}
''');
  }

  Future<void> test_returnType_typeAlias_function() async {
    await resolveTestCode('''
typedef A<T> = void Function(T a);

void f(A<int> Function() a) {}

void g() {
  f(test);
}
''');
    await assertHasFix('''
typedef A<T> = void Function(T a);

void f(A<int> Function() a) {}

void g() {
  f(test);
}

A<int> test() {
}
''');
  }
}

@reflectiveTest
class CreateFunctionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FUNCTION;

  Future<void> assert_returnType_bool(String lineWithTest) async {
    await resolveTestCode('''
void f(bool b) {
  $lineWithTest
  print(b);
}
''');
    await assertHasFix('''
void f(bool b) {
  $lineWithTest
  print(b);
}

bool test() {
}
''');
  }

  Future<void> test_assignment_invocation() async {
    await resolveTestCode('''
bool Function() f = g();
''');
    await assertHasFix('''
bool Function() f = g();

bool Function() g() {
}
''');
  }

  Future<void> test_await_infer_from_parent() async {
    await resolveTestCode('''
Future<void> f() async {
  if (await myUndefinedFunction()) {}
}
''');
    await assertHasFix('''
Future<void> f() async {
  if (await myUndefinedFunction()) {}
}

Future<bool> myUndefinedFunction() async {
}
''');
  }

  Future<void> test_await_no_assignment() async {
    await resolveTestCode('''
Future<void> f() async {
  await myUndefinedFunction();
}
''');
    await assertHasFix('''
Future<void> f() async {
  await myUndefinedFunction();
}

Future<void> myUndefinedFunction() async {
}
''');
  }

  Future<void> test_await_variable_assignment() async {
    await resolveTestCode('''
int x = 1;
Future<void> f() async {
  x = await myUndefinedFunction();
  print(x);
}
''');
    await assertHasFix('''
int x = 1;
Future<void> f() async {
  x = await myUndefinedFunction();
  print(x);
}

Future<int> myUndefinedFunction() async {
}
''');
  }

  Future<void> test_await_variable_declaration() async {
    await resolveTestCode('''
Future<void> f() async {
  var x = await myUndefinedFunction();
  print(x);
}
''');
    await assertHasFix('''
Future<void> f() async {
  var x = await myUndefinedFunction();
  print(x);
}

Future<dynamic> myUndefinedFunction() async {
}
''');
  }

  Future<void> test_await_variable_plusEq() async {
    await resolveTestCode('''
String x = 'hello';
Future<void> f() async {
  x += await myUndefinedFunction();
  print(x);
}
''');
    await assertHasFix('''
String x = 'hello';
Future<void> f() async {
  x += await myUndefinedFunction();
  print(x);
}

Future<String> myUndefinedFunction() async {
}
''');
  }

  Future<void> test_bottomArgument() async {
    await resolveTestCode('''
void f() {
  test(throw 42);
}
''');
    await assertHasFix('''
void f() {
  test(throw 42);
}

void test(param0) {
}
''');
  }

  Future<void> test_duplicateArgumentNames() async {
    await resolveTestCode('''
class C {
  int x = 0;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}
''');
    await assertHasFix('''
class C {
  int x = 0;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}

void bar(int x, int x2) {
}
''');
  }

  Future<void> test_dynamicArgument() async {
    await resolveTestCode('''
void f() {
  dynamic v;
  test(v);
}
''');
    await assertHasFix('''
void f() {
  dynamic v;
  test(v);
}

void test(v) {
}
''');
  }

  Future<void> test_dynamicReturnType() async {
    await resolveTestCode('''
void f() {
  dynamic v = test();
  print(v);
}
''');
    await assertHasFix('''
void f() {
  dynamic v = test();
  print(v);
}

test() {
}
''');
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
int f1() => f2();
''');
    await assertHasFix('''
int f1() => f2();

int f2() {
}
''');
  }

  Future<void> test_fromFunction() async {
    await resolveTestCode('''
void f() {
  int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
}
''');
    await assertHasFix('''
void f() {
  int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  Future<void> test_fromMethod() async {
    await resolveTestCode('''
class A {
  void f() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  void f() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  Future<void> test_functionType_inside_conditional_operator_condition() async {
    await resolveTestCode('''
void f1(int i) {
  f2(f3 ? (v) => v : (v) => v);
}

void f2(int Function(int) f) {}
''');
    await assertNoFix();
  }

  Future<void>
  test_functionType_inside_conditional_operator_condition_FunctionCall() async {
    await resolveTestCode('''
void f1(int i) {
  f2(f3() ? (v) => v : (v) => v);
}

void f2(int Function(int) f) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(f3() ? (v) => v : (v) => v);
}

bool f3() {
}

void f2(int Function(int) f) {}
''');
  }

  Future<void>
  test_functionType_inside_conditional_operator_else_FunctionCall() async {
    await resolveTestCode('''
void f1(int i) {
  f2(i == 0 ? i : f3());
}

void f2(int p) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(i == 0 ? i : f3());
}

int f3() {
}

void f2(int p) {}
''');
  }

  Future<void>
  test_functionType_inside_conditional_operator_then_FunctionCall() async {
    await resolveTestCode('''
void f1(int i) {
  f2(i == 0 ? f3() : i);
}

void f2(int p) {}
''');
    await assertHasFix('''
void f1(int i) {
  f2(i == 0 ? f3() : i);
}

int f3() {
}

void f2(int p) {}
''');
  }

  Future<void> test_functionType_notFunctionType() async {
    await resolveTestCode('''
void f(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    await assertNoFix();
  }

  Future<void> test_generic_type() async {
    await resolveTestCode('''
class A {
  List<int> items = [];
  void f() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A {
  List<int> items = [];
  void f() {
    process(items);
  }
}

void process(List<int> items) {
}
''');
    assertLinkedGroup(
      change.linkedEditGroups[2],
      ['List<int> items) {'],
      expectedSuggestions(LinkedEditSuggestionKind.TYPE, [
        'List<int>',
        'Iterable<int>',
        'Object',
      ]),
    );
  }

  Future<void> test_generic_typeParameter() async {
    await resolveTestCode('''
class A<T> {
  Map<int, T> items = {};
  void f() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A<T> {
  Map<int, T> items = {};
  void f() {
    process(items);
  }
}

void process(Map<int, Object?> items) {
}
''');
  }

  Future<void> test_importType() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
import 'dart:async';
Future getFuture() => null;
''');
    await resolveTestCode('''
import 'lib.dart';
void f() {
  test(getFuture());
}
''');
    await assertHasFix('''
import 'lib.dart';
void f() {
  test(getFuture());
}

void test(Future<dynamic> future) {
}
''');
  }

  Future<void> test_nullArgument() async {
    await resolveTestCode('''
void f() {
  test(null);
}
''');
    await assertHasFix('''
void f() {
  test(null);
}

void test(param0) {
}
''');
  }

  Future<void> test_parameterName_fromIndexExpression() async {
    await resolveTestCode('''
class A {
  int operator[](int _) => 0;

  void foo() {
    bar(this[0]);
  }
}
''');
    await assertHasFix('''
class A {
  int operator[](int _) => 0;

  void foo() {
    bar(this[0]);
  }
}

void bar(int i) {
}
''');
  }

  Future<void> test_record_invocation() async {
    await resolveTestCode('''
(bool,) f = (g(),);
''');
    await assertHasFix('''
(bool,) f = (g(),);

bool g() {
}
''');
  }

  Future<void> test_returnType_bool_and_left() async {
    await assert_returnType_bool('test() && b;');
  }

  Future<void> test_returnType_bool_and_right() async {
    await assert_returnType_bool('b && test();');
  }

  Future<void> test_returnType_bool_assert() async {
    await assert_returnType_bool('assert ( test() );');
  }

  Future<void> test_returnType_bool_do() async {
    await assert_returnType_bool('do {} while ( test() );');
  }

  Future<void> test_returnType_bool_if() async {
    await assert_returnType_bool('if ( test() ) {}');
  }

  Future<void> test_returnType_bool_or_left() async {
    await assert_returnType_bool('test() || b;');
  }

  Future<void> test_returnType_bool_or_right() async {
    await assert_returnType_bool('b || test();');
  }

  Future<void> test_returnType_bool_unaryNegation() async {
    await assert_returnType_bool('!test();');
  }

  Future<void> test_returnType_bool_while() async {
    await assert_returnType_bool('while ( test() ) {}');
  }

  Future<void> test_returnType_closure_expression() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.where((i) => myMethod(i));
}
''');
    await assertHasFix('''
void f(List<int> list) {
  list.where((i) => myMethod(i));
}

bool myMethod(int i) {
}
''');
  }

  Future<void> test_returnType_closure_return() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.where((i) {
    return myMethod(i);
  });
}
''');
    await assertHasFix('''
void f(List<int> list) {
  list.where((i) {
    return myMethod(i);
  });
}

bool myMethod(int i) {
}
''');
  }

  Future<void> test_returnType_fromAssignment_eq() async {
    await resolveTestCode('''
void f() {
  int v;
  v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
void f() {
  int v;
  v = myUndefinedFunction();
  print(v);
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromAssignment_plusEq() async {
    await resolveTestCode('''
void f() {
  num v = 0;
  v += myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
void f() {
  num v = 0;
  v += myUndefinedFunction();
  print(v);
}

num myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromBinary_right() async {
    await resolveTestCode('''
void f() {
  0 + myUndefinedFunction();
}
''');
    await assertHasFix('''
void f() {
  0 + myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromInitializer() async {
    await resolveTestCode('''
void f() {
  int v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
void f() {
  int v = myUndefinedFunction();
  print(v);
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromInvocationArgument() async {
    await resolveTestCode('''
foo(int p) {}
void f() {
  foo( myUndefinedFunction() );
}
''');
    await assertHasFix('''
foo(int p) {}
void f() {
  foo( myUndefinedFunction() );
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromReturn() async {
    await resolveTestCode('''
int f() {
  return myUndefinedFunction();
}
''');
    await assertHasFix('''
int f() {
  return myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_void() async {
    await resolveTestCode('''
void f() {
  myUndefinedFunction();
}
''');
    await assertHasFix('''
void f() {
  myUndefinedFunction();
}

void myUndefinedFunction() {
}
''');
  }
}
