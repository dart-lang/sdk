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
    defineReflectiveTests(CreateFunctionTest);
  });
}

@reflectiveTest
class CreateFunctionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FUNCTION;

  Future<void> assert_returnType_bool(String lineWithTest) async {
    await resolveTestCode('''
main() {
  bool b = true;
  $lineWithTest
  print(b);
}
''');
    await assertHasFix('''
main() {
  bool b = true;
  $lineWithTest
  print(b);
}

bool test() {
}
''');
  }

  Future<void> test_bottomArgument() async {
    await resolveTestCode('''
main() {
  test(throw 42);
}
''');
    await assertHasFix('''
main() {
  test(throw 42);
}

void test(param0) {
}
''');
  }

  Future<void> test_duplicateArgumentNames() async {
    await resolveTestCode('''
class C {
  int x;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}
''');
    await assertHasFix('''
class C {
  int x;
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
main() {
  dynamic v;
  test(v);
}
''');
    await assertHasFix('''
main() {
  dynamic v;
  test(v);
}

void test(v) {
}
''');
  }

  Future<void> test_dynamicReturnType() async {
    await resolveTestCode('''
main() {
  dynamic v = test();
  print(v);
}
''');
    await assertHasFix('''
main() {
  dynamic v = test();
  print(v);
}

test() {
}
''');
  }

  Future<void> test_fromFunction() async {
    await resolveTestCode('''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
}
''');
    await assertHasFix('''
main() {
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
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  Future<void> test_functionType_cascadeSecond() async {
    await resolveTestCode('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}
''');
    await assertHasFix('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_coreFunction() async {
    await resolveTestCode('''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}
''');
    await assertHasFix('''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}

test() {
}
''');
  }

  Future<void> test_functionType_dynamicArgument() async {
    await resolveTestCode('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}
''');
    await assertHasFix('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}

int test(a, b) {
}
''');
  }

  Future<void> test_functionType_function() async {
    await resolveTestCode('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_function_namedArgument() async {
    await resolveTestCode('''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}
''');
    await assertHasFix('''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}

int test(double a, String b) {
}
''');
  }

  Future<void> test_functionType_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
''');
    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

useFunction(int g(A a)) {}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

main() {
  useFunction(test);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  useFunction(test);
}

int test(A a) {
}
''');
  }

  Future<void> test_functionType_notFunctionType() async {
    await resolveTestCode('''
main(A a) {
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
  List<int> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A {
  List<int> items;
  main() {
    process(items);
  }
}

void process(List<int> items) {
}
''');
    assertLinkedGroup(
        change.linkedEditGroups[2],
        ['List<int> items) {'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['List<int>', 'Iterable<int>', 'Object']));
  }

  Future<void> test_generic_typeParameter() async {
    await resolveTestCode('''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}

void process(Map items) {
}
''');
  }

  Future<void> test_importType() async {
    addSource('/home/test/lib/lib.dart', r'''
library lib;
import 'dart:async';
Future getFuture() => null;
''');
    await resolveTestCode('''
import 'lib.dart';
main() {
  test(getFuture());
}
''');
    await assertHasFix('''
import 'lib.dart';
main() {
  test(getFuture());
}

void test(Future future) {
}
''');
  }

  Future<void> test_nullArgument() async {
    await resolveTestCode('''
main() {
  test(null);
}
''');
    await assertHasFix('''
main() {
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

  Future<void> test_returnType_fromAssignment_eq() async {
    await resolveTestCode('''
main() {
  int v;
  v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
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
main() {
  int v;
  v += myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
  int v;
  v += myUndefinedFunction();
  print(v);
}

num myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromBinary_right() async {
    await resolveTestCode('''
main() {
  0 + myUndefinedFunction();
}
''');
    await assertHasFix('''
main() {
  0 + myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromInitializer() async {
    await resolveTestCode('''
main() {
  int v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
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
main() {
  foo( myUndefinedFunction() );
}
''');
    await assertHasFix('''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_fromReturn() async {
    await resolveTestCode('''
int main() {
  return myUndefinedFunction();
}
''');
    await assertHasFix('''
int main() {
  return myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  Future<void> test_returnType_void() async {
    await resolveTestCode('''
main() {
  myUndefinedFunction();
}
''');
    await assertHasFix('''
main() {
  myUndefinedFunction();
}

void myUndefinedFunction() {
}
''');
  }
}
